-- ============================================================
-- BazarNicole · Enterprise Big Data Schema
-- Arquitectura OLTP + OLAP Híbrida para SQLite
-- Nivel: SAP / Odoo / Oracle POS
-- Versión: 4.0.0 - Big Data Edition
-- ============================================================
-- Diseñado para:
--   • Millones de registros sin degradación
--   • Prevención de corrupción SQLite
--   • Consultas analíticas de sub-segundo
--   • Flutter UI anti-freeze
--   • Multi-sucursal, multi-método de pago
--   • OLTP escrituras + OLAP lecturas separadas
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- SECCIÓN 1: PRAGMAS EMPRESARIALES (ejecutar en cada conexión)
-- ──────────────────────────────────────────────────────────

PRAGMA journal_mode = WAL;          -- Write-Ahead Log: lecturas no bloquean escrituras
PRAGMA synchronous = NORMAL;        -- Balance seguridad/rendimiento (no OFF, no FULL)
PRAGMA cache_size = -65536;         -- 64 MB de caché en memoria (negativo = KB)
PRAGMA temp_store = MEMORY;         -- Tablas temporales en RAM
PRAGMA mmap_size = 536870912;       -- Memory-mapped I/O: 512 MB
PRAGMA page_size = 4096;            -- 4 KB por página (óptimo SSD/HDD)
PRAGMA auto_vacuum = INCREMENTAL;   -- Recupera espacio sin bloquear
PRAGMA foreign_keys = ON;
PRAGMA busy_timeout = 10000;        -- 10 seg de espera si BD ocupada
PRAGMA wal_autocheckpoint = 1000;   -- Checkpoint cada 1000 páginas WAL
PRAGMA optimize;                    -- Ejecutar antes de queries analíticos

-- ──────────────────────────────────────────────────────────
-- SECCIÓN 2: CAPAS OLTP — TABLAS TRANSACCIONALES MAESTRAS
-- ──────────────────────────────────────────────────────────

-- 2.1 Catálogos base
CREATE TABLE IF NOT EXISTS stores (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL UNIQUE,
  address     TEXT,
  phone       TEXT,
  tax_id      TEXT,
  is_active   INTEGER NOT NULL DEFAULT 1,
  created_at  TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE IF NOT EXISTS categories (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL UNIQUE,
  parent_id   INTEGER REFERENCES categories(id),
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_active   INTEGER NOT NULL DEFAULT 1
);

-- 2.2 Productos (tabla crítica de alto acceso)
CREATE TABLE IF NOT EXISTS products (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  uid           TEXT    UNIQUE,
  name          TEXT    NOT NULL,
  sku           TEXT    NOT NULL UNIQUE,
  aux_code      TEXT,
  description   TEXT,
  tags          TEXT,
  category_id   INTEGER REFERENCES categories(id),
  store_id      INTEGER REFERENCES stores(id),
  price         REAL    NOT NULL DEFAULT 0,
  cost_price    REAL    NOT NULL DEFAULT 0,
  iva_rate      REAL    NOT NULL DEFAULT 0,
  profit_iva    REAL    NOT NULL DEFAULT 0,
  images        TEXT,
  is_active     INTEGER NOT NULL DEFAULT 1,
  -- Columnas desnormalizadas para evitar JOINs en POS (crítico rendimiento)
  category_name TEXT    GENERATED ALWAYS AS (NULL) VIRTUAL,  -- se sobreescribe con trigger
  created_at    TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at    TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

-- 2.3 Inventario con constraint OLTP estricto
CREATE TABLE IF NOT EXISTS inventory (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id  INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  store_id    INTEGER NOT NULL REFERENCES stores(id)   ON DELETE CASCADE,
  stock       INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  min_stock   INTEGER NOT NULL DEFAULT 0,
  max_stock   INTEGER,
  UNIQUE(product_id, store_id)
);

-- 2.4 Clientes con segmentación
CREATE TABLE IF NOT EXISTS clients (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  name           TEXT    NOT NULL,
  phone          TEXT,
  email          TEXT,
  notes          TEXT,
  -- Segmentación RFM pre-calculada (actualizada por background job)
  rfm_recency    INTEGER DEFAULT 0,   -- días desde última compra
  rfm_frequency  INTEGER DEFAULT 0,   -- número de compras
  rfm_monetary   REAL    DEFAULT 0,   -- total gastado
  rfm_score      INTEGER DEFAULT 0,   -- 1-5 calculado
  rfm_segment    TEXT    DEFAULT 'new', -- 'champion','loyal','at_risk','lost','new'
  total_purchases INTEGER NOT NULL DEFAULT 0,
  total_spent    REAL    NOT NULL DEFAULT 0,
  last_purchase_at TEXT,
  created_at     TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

-- 2.5 Proveedores
CREATE TABLE IF NOT EXISTS suppliers (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT    NOT NULL UNIQUE,
  phone      TEXT,
  email      TEXT,
  tax_id     TEXT,
  address    TEXT,
  is_active  INTEGER NOT NULL DEFAULT 1,
  created_at TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

-- 2.6 Compras
CREATE TABLE IF NOT EXISTS purchases (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id     INTEGER NOT NULL REFERENCES stores(id),
  supplier_id  INTEGER          REFERENCES suppliers(id),
  total        REAL    NOT NULL DEFAULT 0,
  tax_total    REAL    NOT NULL DEFAULT 0,
  notes        TEXT,
  status       TEXT    NOT NULL DEFAULT 'received' CHECK(status IN ('draft','received','cancelled')),
  date         TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  -- Partición lógica por año-mes para filtros rápidos
  year_month   TEXT    GENERATED ALWAYS AS (substr(date,1,7)) STORED
);

CREATE TABLE IF NOT EXISTS purchase_items (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  purchase_id  INTEGER NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  product_id   INTEGER NOT NULL REFERENCES products(id),
  quantity     INTEGER NOT NULL CHECK(quantity > 0),
  cost         REAL    NOT NULL CHECK(cost >= 0),
  subtotal     REAL    GENERATED ALWAYS AS (quantity * cost) STORED
);

-- 2.7 Ventas OLTP (tabla más crítica del sistema)
CREATE TABLE IF NOT EXISTS sales (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id    INTEGER NOT NULL REFERENCES stores(id),
  client_id   INTEGER          REFERENCES clients(id),
  date        TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  total       REAL    NOT NULL DEFAULT 0,
  discount    REAL    NOT NULL DEFAULT 0,
  tax_total   REAL    NOT NULL DEFAULT 0,
  status      TEXT    NOT NULL DEFAULT 'completed' CHECK(status IN ('completed','cancelled','refunded')),
  notes       TEXT,
  -- Columnas de partición lógica GENERADAS (evitan cálculos en queries)
  sale_date   TEXT    GENERATED ALWAYS AS (substr(date,1,10)) STORED,
  year_month  TEXT    GENERATED ALWAYS AS (substr(date,1,7))  STORED,
  year_week   TEXT    GENERATED ALWAYS AS (
                strftime('%Y-W%W', date)
              ) STORED,
  sale_year   INTEGER GENERATED ALWAYS AS (CAST(substr(date,1,4) AS INTEGER)) STORED,
  sale_month  INTEGER GENERATED ALWAYS AS (CAST(substr(date,6,2) AS INTEGER)) STORED,
  sale_day    INTEGER GENERATED ALWAYS AS (CAST(substr(date,9,2) AS INTEGER)) STORED
);

CREATE TABLE IF NOT EXISTS sale_items (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id     INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id  INTEGER NOT NULL REFERENCES products(id),
  quantity    INTEGER NOT NULL CHECK(quantity > 0),
  price       REAL    NOT NULL CHECK(price >= 0),
  cost_price  REAL    NOT NULL DEFAULT 0,   -- snapshot del costo al momento de venta
  discount    REAL    NOT NULL DEFAULT 0,
  subtotal    REAL    GENERATED ALWAYS AS (quantity * price - discount) STORED,
  profit      REAL    GENERATED ALWAYS AS (quantity * (price - cost_price) - discount) STORED
);

-- 2.8 Movimientos de inventario (audit trail completo)
CREATE TABLE IF NOT EXISTS inventory_movements (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id    INTEGER NOT NULL REFERENCES products(id),
  from_store_id INTEGER NOT NULL REFERENCES stores(id),
  to_store_id   INTEGER NOT NULL REFERENCES stores(id),
  quantity      INTEGER NOT NULL,
  reason        TEXT    NOT NULL DEFAULT 'transfer' CHECK(reason IN ('transfer','adjustment','sale','purchase','return','damage')),
  reference_id  INTEGER,   -- sale_id o purchase_id que originó el movimiento
  date          TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

-- 2.9 Métodos de pago
CREATE TABLE IF NOT EXISTS payment_methods (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  name    TEXT    NOT NULL UNIQUE,
  is_cash INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

-- 2.10 Sesiones de caja
CREATE TABLE IF NOT EXISTS cash_sessions (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id        INTEGER NOT NULL REFERENCES stores(id),
  user_id         INTEGER          REFERENCES users(id),
  opening_amount  REAL    NOT NULL DEFAULT 0,
  closing_amount  REAL,
  expected_amount REAL,              -- total calculado al cerrar
  difference      REAL,              -- closing - expected
  opened_at       TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  closed_at       TEXT,
  status          TEXT    NOT NULL DEFAULT 'open' CHECK(status IN ('open','closed','force_closed')),
  notes           TEXT
);

-- 2.11 Movimientos de caja detallados
CREATE TABLE IF NOT EXISTS cash_movements (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id  INTEGER NOT NULL REFERENCES cash_sessions(id),
  type        TEXT    NOT NULL CHECK(type IN ('income','expense','opening','closing','sale','refund')),
  amount      REAL    NOT NULL,
  method      TEXT    NOT NULL DEFAULT 'Efectivo',
  description TEXT,
  reference_id INTEGER,
  created_at  TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  -- Partición lógica
  mov_date    TEXT    GENERATED ALWAYS AS (substr(created_at,1,10)) STORED
);

-- 2.12 Pagos de venta (multi-método)
CREATE TABLE IF NOT EXISTS sale_payments (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id   INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  method_id INTEGER NOT NULL REFERENCES payment_methods(id),
  amount    REAL    NOT NULL CHECK(amount > 0)
);

-- 2.13 Ventas a crédito
CREATE TABLE IF NOT EXISTS credit_sales (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id   INTEGER NOT NULL UNIQUE REFERENCES sales(id),
  total     REAL    NOT NULL,
  paid      REAL    NOT NULL DEFAULT 0,
  balance   REAL    GENERATED ALWAYS AS (total - paid) STORED,
  status    TEXT    NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','partial','paid','overdue','cancelled')),
  due_date  TEXT,
  created_at TEXT   NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE IF NOT EXISTS credit_payments (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  credit_sale_id  INTEGER NOT NULL REFERENCES credit_sales(id),
  amount          REAL    NOT NULL CHECK(amount > 0),
  method_id       INTEGER NOT NULL REFERENCES payment_methods(id),
  date            TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  notes           TEXT
);

-- 2.14 Denominaciones de efectivo
CREATE TABLE IF NOT EXISTS cash_denominations (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL REFERENCES cash_sessions(id),
  value      REAL    NOT NULL,
  quantity   INTEGER NOT NULL DEFAULT 0,
  subtotal   REAL    GENERATED ALWAYS AS (value * quantity) STORED
);

-- 2.15 Usuarios con roles
CREATE TABLE IF NOT EXISTS users (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  uid        TEXT    NOT NULL UNIQUE,
  email      TEXT    NOT NULL UNIQUE,
  password   TEXT    NOT NULL,
  name       TEXT    NOT NULL,
  lastname   TEXT    NOT NULL,
  role       TEXT    NOT NULL DEFAULT 'cajero' CHECK(role IN ('admin','supervisor','cajero','bodeguero')),
  is_active  INTEGER NOT NULL DEFAULT 1,
  store_id   INTEGER          REFERENCES stores(id),
  last_login TEXT,
  created_at TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

-- ──────────────────────────────────────────────────────────
-- SECCIÓN 3: ÍNDICES EMPRESARIALES CRÍTICOS
-- ──────────────────────────────────────────────────────────
-- Principio: índice por cada JOIN, WHERE y ORDER BY frecuente
-- Regla: índices compuestos en el orden (igualdad, rango, orden)

-- 3.1 Productos
CREATE INDEX IF NOT EXISTS idx_products_store_active
  ON products(store_id, is_active);

CREATE INDEX IF NOT EXISTS idx_products_category_active
  ON products(category_id, is_active);

CREATE INDEX IF NOT EXISTS idx_products_sku
  ON products(sku);

-- 3.2 Inventario
CREATE INDEX IF NOT EXISTS idx_inventory_product_store
  ON inventory(product_id, store_id);

CREATE INDEX IF NOT EXISTS idx_inventory_store_stock
  ON inventory(store_id, stock);

-- 3.3 Ventas — los índices más críticos del sistema
CREATE INDEX IF NOT EXISTS idx_sales_store_date
  ON sales(store_id, sale_date DESC);

CREATE INDEX IF NOT EXISTS idx_sales_year_month_store
  ON sales(year_month, store_id);

CREATE INDEX IF NOT EXISTS idx_sales_client_date
  ON sales(client_id, sale_date DESC);

CREATE INDEX IF NOT EXISTS idx_sales_status_date
  ON sales(status, sale_date DESC);

CREATE INDEX IF NOT EXISTS idx_sales_year_store
  ON sales(sale_year, store_id, total);

-- 3.4 Items de venta
CREATE INDEX IF NOT EXISTS idx_sale_items_sale
  ON sale_items(sale_id);

CREATE INDEX IF NOT EXISTS idx_sale_items_product_sale
  ON sale_items(product_id, sale_id);

-- 3.5 Compras
CREATE INDEX IF NOT EXISTS idx_purchases_store_date
  ON purchases(store_id, year_month DESC);

CREATE INDEX IF NOT EXISTS idx_purchases_supplier
  ON purchases(supplier_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase
  ON purchase_items(purchase_id);

CREATE INDEX IF NOT EXISTS idx_purchase_items_product
  ON purchase_items(product_id, purchase_id);

-- 3.6 Caja
CREATE INDEX IF NOT EXISTS idx_cash_sessions_store_status
  ON cash_sessions(store_id, status, opened_at DESC);

CREATE INDEX IF NOT EXISTS idx_cash_movements_session_date
  ON cash_movements(session_id, mov_date DESC);

CREATE INDEX IF NOT EXISTS idx_cash_movements_date_type
  ON cash_movements(mov_date, type, amount);

-- 3.7 Crédito
CREATE INDEX IF NOT EXISTS idx_credit_sales_status
  ON credit_sales(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_credit_payments_credit
  ON credit_payments(credit_sale_id, date DESC);

-- 3.8 Movimientos inventario
CREATE INDEX IF NOT EXISTS idx_inv_movements_product_date
  ON inventory_movements(product_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_inv_movements_store_date
  ON inventory_movements(from_store_id, date DESC);

-- 3.9 Clientes (RFM)
CREATE INDEX IF NOT EXISTS idx_clients_rfm_segment
  ON clients(rfm_segment, rfm_score DESC);

CREATE INDEX IF NOT EXISTS idx_clients_last_purchase
  ON clients(last_purchase_at DESC);

-- ──────────────────────────────────────────────────────────
-- SECCIÓN 4: CAPA OLAP — TABLAS ANALÍTICAS (Big Data Local)
-- ──────────────────────────────────────────────────────────
-- Estas tablas son el "Data Warehouse local"
-- Se calculan en background y se leen desde la UI sin costo

-- 4.1 Resumen DIARIO de ventas por tienda
CREATE TABLE IF NOT EXISTS summary_sales_daily (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id        INTEGER NOT NULL REFERENCES stores(id),
  sale_date       TEXT    NOT NULL,                -- YYYY-MM-DD
  total_sales     INTEGER NOT NULL DEFAULT 0,      -- número de transacciones
  total_revenue   REAL    NOT NULL DEFAULT 0,      -- suma de totales
  total_cost      REAL    NOT NULL DEFAULT 0,      -- costo de mercadería vendida
  total_profit    REAL    NOT NULL DEFAULT 0,      -- ganancia bruta
  total_discount  REAL    NOT NULL DEFAULT 0,
  total_tax       REAL    NOT NULL DEFAULT 0,
  avg_ticket      REAL    NOT NULL DEFAULT 0,      -- ticket promedio
  max_ticket      REAL    NOT NULL DEFAULT 0,
  min_ticket      REAL    NOT NULL DEFAULT 0,
  units_sold      INTEGER NOT NULL DEFAULT 0,      -- unidades totales
  unique_clients  INTEGER NOT NULL DEFAULT 0,      -- clientes únicos
  credit_sales    INTEGER NOT NULL DEFAULT 0,      -- ventas a crédito
  cash_sales      INTEGER NOT NULL DEFAULT 0,
  calculated_at   TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(store_id, sale_date)
);

CREATE INDEX IF NOT EXISTS idx_summary_daily_store_date
  ON summary_sales_daily(store_id, sale_date DESC);

-- 4.2 Resumen SEMANAL
CREATE TABLE IF NOT EXISTS summary_sales_weekly (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id        INTEGER NOT NULL REFERENCES stores(id),
  year_week       TEXT    NOT NULL,                -- YYYY-Www
  total_sales     INTEGER NOT NULL DEFAULT 0,
  total_revenue   REAL    NOT NULL DEFAULT 0,
  total_cost      REAL    NOT NULL DEFAULT 0,
  total_profit    REAL    NOT NULL DEFAULT 0,
  total_discount  REAL    NOT NULL DEFAULT 0,
  avg_ticket      REAL    NOT NULL DEFAULT 0,
  units_sold      INTEGER NOT NULL DEFAULT 0,
  unique_clients  INTEGER NOT NULL DEFAULT 0,
  best_day        TEXT,                            -- día de mayor venta
  best_day_revenue REAL   DEFAULT 0,
  calculated_at   TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(store_id, year_week)
);

-- 4.3 Resumen MENSUAL
CREATE TABLE IF NOT EXISTS summary_sales_monthly (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id        INTEGER NOT NULL REFERENCES stores(id),
  year_month      TEXT    NOT NULL,                -- YYYY-MM
  total_sales     INTEGER NOT NULL DEFAULT 0,
  total_revenue   REAL    NOT NULL DEFAULT 0,
  total_cost      REAL    NOT NULL DEFAULT 0,
  total_profit    REAL    NOT NULL DEFAULT 0,
  total_discount  REAL    NOT NULL DEFAULT 0,
  total_tax       REAL    NOT NULL DEFAULT 0,
  avg_ticket      REAL    NOT NULL DEFAULT 0,
  units_sold      INTEGER NOT NULL DEFAULT 0,
  unique_clients  INTEGER NOT NULL DEFAULT 0,
  new_clients     INTEGER NOT NULL DEFAULT 0,
  credit_ratio    REAL    NOT NULL DEFAULT 0,      -- % ventas a crédito
  top_product_id  INTEGER,
  top_product_revenue REAL DEFAULT 0,
  calculated_at   TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(store_id, year_month)
);

CREATE INDEX IF NOT EXISTS idx_summary_monthly_store_date
  ON summary_sales_monthly(store_id, year_month DESC);

-- 4.4 Resumen ANUAL
CREATE TABLE IF NOT EXISTS summary_sales_annual (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id        INTEGER NOT NULL REFERENCES stores(id),
  sale_year       INTEGER NOT NULL,
  total_sales     INTEGER NOT NULL DEFAULT 0,
  total_revenue   REAL    NOT NULL DEFAULT 0,
  total_cost      REAL    NOT NULL DEFAULT 0,
  total_profit    REAL    NOT NULL DEFAULT 0,
  total_discount  REAL    NOT NULL DEFAULT 0,
  avg_monthly_revenue REAL NOT NULL DEFAULT 0,
  best_month      TEXT,
  best_month_revenue REAL DEFAULT 0,
  units_sold      INTEGER NOT NULL DEFAULT 0,
  unique_clients  INTEGER NOT NULL DEFAULT 0,
  calculated_at   TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(store_id, sale_year)
);

-- 4.5 Analytics por PRODUCTO (rolling 30 días, 90 días, 1 año)
CREATE TABLE IF NOT EXISTS analytics_product (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id          INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  store_id            INTEGER NOT NULL REFERENCES stores(id),
  period_days         INTEGER NOT NULL,               -- 7, 30, 90, 365
  units_sold          INTEGER NOT NULL DEFAULT 0,
  revenue             REAL    NOT NULL DEFAULT 0,
  cost_total          REAL    NOT NULL DEFAULT 0,
  profit              REAL    NOT NULL DEFAULT 0,
  profit_margin       REAL    NOT NULL DEFAULT 0,     -- %
  avg_daily_sales     REAL    NOT NULL DEFAULT 0,
  rotation_rate       REAL    NOT NULL DEFAULT 0,     -- unidades/día
  days_of_stock       REAL    NOT NULL DEFAULT 0,     -- stock / avg_daily_sales
  saleability_score   INTEGER NOT NULL DEFAULT 0,     -- 0-100
  rank_by_revenue     INTEGER NOT NULL DEFAULT 0,
  rank_by_units       INTEGER NOT NULL DEFAULT 0,
  calculated_at       TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(product_id, store_id, period_days)
);

CREATE INDEX IF NOT EXISTS idx_analytics_product_store_period
  ON analytics_product(store_id, period_days, saleability_score DESC);

CREATE INDEX IF NOT EXISTS idx_analytics_product_rank
  ON analytics_product(store_id, period_days, rank_by_revenue);

-- 4.6 Analytics por CATEGORÍA
CREATE TABLE IF NOT EXISTS analytics_category (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id     INTEGER NOT NULL REFERENCES categories(id),
  store_id        INTEGER NOT NULL REFERENCES stores(id),
  period_days     INTEGER NOT NULL,
  total_products  INTEGER NOT NULL DEFAULT 0,
  units_sold      INTEGER NOT NULL DEFAULT 0,
  revenue         REAL    NOT NULL DEFAULT 0,
  profit          REAL    NOT NULL DEFAULT 0,
  profit_margin   REAL    NOT NULL DEFAULT 0,
  avg_margin      REAL    NOT NULL DEFAULT 0,
  revenue_share   REAL    NOT NULL DEFAULT 0,         -- % del total
  calculated_at   TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(category_id, store_id, period_days)
);

-- 4.7 Analytics de CLIENTES (RFM completo)
CREATE TABLE IF NOT EXISTS analytics_customer (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  client_id           INTEGER NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  period_days         INTEGER NOT NULL,
  total_orders        INTEGER NOT NULL DEFAULT 0,
  total_revenue       REAL    NOT NULL DEFAULT 0,
  avg_ticket          REAL    NOT NULL DEFAULT 0,
  max_ticket          REAL    NOT NULL DEFAULT 0,
  days_since_purchase INTEGER NOT NULL DEFAULT 9999,
  rfm_r               INTEGER NOT NULL DEFAULT 0,     -- 1-5
  rfm_f               INTEGER NOT NULL DEFAULT 0,
  rfm_m               INTEGER NOT NULL DEFAULT 0,
  rfm_total           INTEGER NOT NULL DEFAULT 0,     -- R+F+M
  segment             TEXT    NOT NULL DEFAULT 'new',
  ltv                 REAL    NOT NULL DEFAULT 0,     -- Lifetime Value
  calculated_at       TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(client_id, period_days)
);

-- 4.8 Analytics de CAJA
CREATE TABLE IF NOT EXISTS analytics_cash (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id        INTEGER NOT NULL REFERENCES stores(id),
  period          TEXT    NOT NULL,                   -- YYYY-MM-DD, YYYY-MM o YYYY
  period_type     TEXT    NOT NULL CHECK(period_type IN ('day','month','year')),
  total_income    REAL    NOT NULL DEFAULT 0,
  total_expense   REAL    NOT NULL DEFAULT 0,
  net_cash        REAL    NOT NULL DEFAULT 0,
  total_cash      REAL    NOT NULL DEFAULT 0,
  total_card      REAL    NOT NULL DEFAULT 0,
  total_transfer  REAL    NOT NULL DEFAULT 0,
  sessions_count  INTEGER NOT NULL DEFAULT 0,
  avg_opening     REAL    NOT NULL DEFAULT 0,
  calculated_at   TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(store_id, period, period_type)
);

-- 4.9 KPIs empresariales en tiempo real
CREATE TABLE IF NOT EXISTS kpi_snapshot (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id        INTEGER NOT NULL REFERENCES stores(id),
  snapshot_date   TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  -- Ventas
  revenue_today   REAL    NOT NULL DEFAULT 0,
  revenue_week    REAL    NOT NULL DEFAULT 0,
  revenue_month   REAL    NOT NULL DEFAULT 0,
  revenue_year    REAL    NOT NULL DEFAULT 0,
  -- Transacciones
  sales_today     INTEGER NOT NULL DEFAULT 0,
  sales_week      INTEGER NOT NULL DEFAULT 0,
  sales_month     INTEGER NOT NULL DEFAULT 0,
  -- Rentabilidad
  profit_today    REAL    NOT NULL DEFAULT 0,
  profit_month    REAL    NOT NULL DEFAULT 0,
  margin_month    REAL    NOT NULL DEFAULT 0,         -- % margen
  -- Inventario
  low_stock_count INTEGER NOT NULL DEFAULT 0,         -- productos bajo mínimo
  total_inventory_value REAL NOT NULL DEFAULT 0,      -- inversión en stock
  -- Clientes
  active_clients  INTEGER NOT NULL DEFAULT 0,         -- compraron últimos 30 días
  new_clients_month INTEGER NOT NULL DEFAULT 0,
  -- Crédito
  credit_balance  REAL    NOT NULL DEFAULT 0,         -- total por cobrar
  overdue_credit  REAL    NOT NULL DEFAULT 0,
  -- Comparativas
  revenue_vs_last_month REAL DEFAULT 0,               -- % variación
  revenue_vs_last_year  REAL DEFAULT 0,
  UNIQUE(store_id, substr(snapshot_date,1,10))        -- 1 snapshot por día por tienda
);

CREATE INDEX IF NOT EXISTS idx_kpi_store_date
  ON kpi_snapshot(store_id, snapshot_date DESC);

-- 4.10 Caché analítico (queries pre-computadas serializadas)
CREATE TABLE IF NOT EXISTS analytics_cache (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  cache_key   TEXT    NOT NULL UNIQUE,               -- hash o nombre del query
  payload     TEXT    NOT NULL,                      -- JSON serializado
  ttl_seconds INTEGER NOT NULL DEFAULT 300,           -- tiempo de vida
  created_at  TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  expires_at  TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_analytics_cache_key_exp
  ON analytics_cache(cache_key, expires_at);

-- 4.11 Cola de jobs en background
CREATE TABLE IF NOT EXISTS background_jobs (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  job_type     TEXT    NOT NULL,                     -- 'recalculate_daily','update_rfm','rebuild_kpi'
  store_id     INTEGER          REFERENCES stores(id),
  payload      TEXT,                                  -- JSON parámetros
  status       TEXT    NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','running','done','failed')),
  priority     INTEGER NOT NULL DEFAULT 5,            -- 1=alta .. 10=baja
  attempts     INTEGER NOT NULL DEFAULT 0,
  error_msg    TEXT,
  scheduled_at TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  started_at   TEXT,
  finished_at  TEXT
);

CREATE INDEX IF NOT EXISTS idx_bg_jobs_status_priority
  ON background_jobs(status, priority, scheduled_at);

-- 4.12 Tabla de tendencias para sparklines en dashboard
CREATE TABLE IF NOT EXISTS trend_sparklines (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id    INTEGER NOT NULL REFERENCES stores(id),
  metric      TEXT    NOT NULL,                      -- 'revenue','units','profit','clients'
  period_type TEXT    NOT NULL,                      -- 'daily_7','daily_30','monthly_12'
  data_json   TEXT    NOT NULL,                      -- [{date,value}] JSON
  calculated_at TEXT  NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE(store_id, metric, period_type)
);

-- ──────────────────────────────────────────────────────────
-- SECCIÓN 5: TRIGGERS EMPRESARIALES
-- ──────────────────────────────────────────────────────────

-- 5.1 Actualizar updated_at en productos
CREATE TRIGGER IF NOT EXISTS trg_products_updated_at
  AFTER UPDATE ON products
  FOR EACH ROW
BEGIN
  UPDATE products SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')
  WHERE id = OLD.id;
END;

-- 5.2 Actualizar métricas de cliente tras venta completada
CREATE TRIGGER IF NOT EXISTS trg_sale_update_client_metrics
  AFTER INSERT ON sales
  FOR EACH ROW
  WHEN NEW.client_id IS NOT NULL AND NEW.status = 'completed'
BEGIN
  UPDATE clients SET
    total_purchases   = total_purchases + 1,
    total_spent       = total_spent + NEW.total,
    last_purchase_at  = NEW.date
  WHERE id = NEW.client_id;
END;

-- 5.3 Descontar stock al registrar una venta (OLTP crítico)
CREATE TRIGGER IF NOT EXISTS trg_sale_item_decrement_stock
  AFTER INSERT ON sale_items
  FOR EACH ROW
BEGIN
  UPDATE inventory SET stock = stock - NEW.quantity
  WHERE product_id = NEW.product_id
    AND store_id = (SELECT store_id FROM sales WHERE id = NEW.sale_id);
END;

-- 5.4 Restaurar stock si venta es cancelada
CREATE TRIGGER IF NOT EXISTS trg_sale_cancel_restore_stock
  AFTER UPDATE ON sales
  FOR EACH ROW
  WHEN NEW.status = 'cancelled' AND OLD.status != 'cancelled'
BEGIN
  UPDATE inventory
  SET stock = stock + si.quantity
  FROM sale_items si
  WHERE si.sale_id = NEW.id
    AND inventory.product_id = si.product_id
    AND inventory.store_id = NEW.store_id;
END;

-- 5.5 Incrementar stock al recibir compra
CREATE TRIGGER IF NOT EXISTS trg_purchase_item_increment_stock
  AFTER INSERT ON purchase_items
  FOR EACH ROW
BEGIN
  INSERT INTO inventory(product_id, store_id, stock)
  VALUES (
    NEW.product_id,
    (SELECT store_id FROM purchases WHERE id = NEW.purchase_id),
    NEW.quantity
  )
  ON CONFLICT(product_id, store_id) DO UPDATE
    SET stock = stock + NEW.quantity;
END;

-- 5.6 Actualizar crédito tras pago parcial
CREATE TRIGGER IF NOT EXISTS trg_credit_payment_update_balance
  AFTER INSERT ON credit_payments
  FOR EACH ROW
BEGIN
  UPDATE credit_sales
  SET
    paid   = paid + NEW.amount,
    status = CASE
               WHEN (paid + NEW.amount) >= total THEN 'paid'
               WHEN (paid + NEW.amount) > 0      THEN 'partial'
               ELSE 'pending'
             END
  WHERE id = NEW.credit_sale_id;
END;

-- 5.7 Encolar recálculo de resúmenes analíticos al insertar venta
CREATE TRIGGER IF NOT EXISTS trg_sale_enqueue_analytics
  AFTER INSERT ON sales
  FOR EACH ROW
  WHEN NEW.status = 'completed'
BEGIN
  INSERT INTO background_jobs(job_type, store_id, payload, priority)
  VALUES (
    'recalculate_daily',
    NEW.store_id,
    json_object('date', NEW.sale_date, 'store_id', NEW.store_id),
    2
  );
END;

-- 5.8 Invalidar caché analítico al insertar venta
CREATE TRIGGER IF NOT EXISTS trg_sale_invalidate_cache
  AFTER INSERT ON sales
  FOR EACH ROW
BEGIN
  DELETE FROM analytics_cache
  WHERE cache_key LIKE ('store_' || NEW.store_id || '%');
END;

-- ──────────────────────────────────────────────────────────
-- SECCIÓN 6: VISTAS ANALÍTICAS (Materialized View simuladas)
-- ──────────────────────────────────────────────────────────

-- 6.1 Vista de ventas enriquecida (evita JOINs repetitivos)
CREATE VIEW IF NOT EXISTS v_sales_enriched AS
SELECT
  s.id,
  s.store_id,
  st.name         AS store_name,
  s.client_id,
  c.name          AS client_name,
  s.date,
  s.sale_date,
  s.year_month,
  s.year_week,
  s.sale_year,
  s.sale_month,
  s.total,
  s.discount,
  s.tax_total,
  s.status,
  (SELECT COUNT(*) FROM sale_items si WHERE si.sale_id = s.id) AS items_count,
  (SELECT pm.name FROM sale_payments sp
   JOIN payment_methods pm ON pm.id = sp.method_id
   WHERE sp.sale_id = s.id
   ORDER BY sp.amount DESC LIMIT 1) AS primary_payment_method
FROM sales s
JOIN stores st ON st.id = s.store_id
LEFT JOIN clients c ON c.id = s.client_id;

-- 6.2 Vista de rentabilidad por producto (OLAP)
CREATE VIEW IF NOT EXISTS v_product_profitability AS
SELECT
  p.id            AS product_id,
  p.name          AS product_name,
  p.sku,
  p.store_id,
  p.category_id,
  cat.name        AS category_name,
  p.price,
  p.cost_price,
  p.price - p.cost_price                          AS margin_abs,
  CASE WHEN p.cost_price > 0
    THEN ROUND(((p.price - p.cost_price) / p.cost_price) * 100, 2)
    ELSE 0 END                                    AS margin_pct,
  COALESCE(inv.stock, 0)                          AS current_stock,
  COALESCE(inv.stock * p.cost_price, 0)           AS inventory_value,
  COALESCE(ap30.units_sold, 0)                    AS units_sold_30d,
  COALESCE(ap30.revenue, 0)                       AS revenue_30d,
  COALESCE(ap30.profit, 0)                        AS profit_30d,
  COALESCE(ap30.saleability_score, 0)             AS saleability_score,
  COALESCE(ap30.days_of_stock, 999)               AS days_of_stock
FROM products p
LEFT JOIN categories cat ON cat.id = p.category_id
LEFT JOIN inventory inv  ON inv.product_id = p.id AND inv.store_id = p.store_id
LEFT JOIN analytics_product ap30
  ON ap30.product_id = p.id AND ap30.store_id = p.store_id AND ap30.period_days = 30
WHERE p.is_active = 1;

-- 6.3 Vista de dashboard de caja
CREATE VIEW IF NOT EXISTS v_cash_dashboard AS
SELECT
  cs.id           AS session_id,
  cs.store_id,
  st.name         AS store_name,
  cs.opened_at,
  cs.closed_at,
  cs.status,
  cs.opening_amount,
  cs.closing_amount,
  cs.expected_amount,
  COALESCE(cs.closing_amount - cs.expected_amount, 0) AS difference,
  (SELECT COALESCE(SUM(amount),0) FROM cash_movements
   WHERE session_id = cs.id AND type IN ('income','sale')) AS total_income,
  (SELECT COALESCE(SUM(amount),0) FROM cash_movements
   WHERE session_id = cs.id AND type = 'expense') AS total_expense
FROM cash_sessions cs
JOIN stores st ON st.id = cs.store_id;

-- 6.4 Vista de cartera de crédito
CREATE VIEW IF NOT EXISTS v_credit_portfolio AS
SELECT
  cr.id           AS credit_id,
  cr.sale_id,
  s.date          AS sale_date,
  s.store_id,
  c.id            AS client_id,
  c.name          AS client_name,
  c.phone         AS client_phone,
  cr.total,
  cr.paid,
  cr.balance,
  cr.status,
  cr.due_date,
  CAST(julianday('now') - julianday(COALESCE(cr.due_date, s.date)) AS INTEGER) AS days_overdue
FROM credit_sales cr
JOIN sales s ON s.id = cr.sale_id
LEFT JOIN clients c ON c.id = s.client_id
WHERE cr.status NOT IN ('paid','cancelled');

-- ──────────────────────────────────────────────────────────
-- SECCIÓN 7: QUERIES ANALÍTICOS OPTIMIZADOS (ejemplos reales)
-- ──────────────────────────────────────────────────────────

-- Q1: Top 10 productos más rentables últimos 30 días (usa índice OLAP)
-- SELECT product_id, product_name, revenue_30d, profit_30d, saleability_score
-- FROM v_product_profitability
-- WHERE store_id = ?
-- ORDER BY profit_30d DESC LIMIT 10;

-- Q2: Revenue diario últimos 90 días por tienda (usa summary pre-calculado)
-- SELECT sale_date, total_revenue, total_profit, avg_ticket, units_sold
-- FROM summary_sales_daily
-- WHERE store_id = ? AND sale_date >= date('now','-90 days')
-- ORDER BY sale_date DESC;

-- Q3: Evolución mensual últimos 24 meses (NO toca sales, va al summary)
-- SELECT year_month, total_revenue, total_profit, total_sales, unique_clients
-- FROM summary_sales_monthly
-- WHERE store_id = ?
-- ORDER BY year_month DESC LIMIT 24;

-- Q4: Clientes con deuda vencida (cartera vencida)
-- SELECT * FROM v_credit_portfolio
-- WHERE days_overdue > 0 AND store_id = ?
-- ORDER BY balance DESC;

-- Q5: KPI snapshot más reciente
-- SELECT * FROM kpi_snapshot
-- WHERE store_id = ? ORDER BY snapshot_date DESC LIMIT 1;

-- Q6: Paginación extrema de ventas (OLTP - sin COUNT)
-- SELECT * FROM v_sales_enriched
-- WHERE store_id = ? AND sale_date <= ?   -- cursor: última fecha vista
--   AND id < ?                             -- cursor: último id visto
-- ORDER BY sale_date DESC, id DESC
-- LIMIT 50;

-- Q7: Inventario crítico (stock bajo mínimo)
-- SELECT p.name, p.sku, inv.stock, inv.min_stock,
--        inv.stock * p.cost_price AS value_at_risk
-- FROM inventory inv
-- JOIN products p ON p.id = inv.product_id
-- WHERE inv.store_id = ? AND inv.stock <= inv.min_stock AND p.is_active = 1
-- ORDER BY (inv.stock * p.cost_price) DESC;

-- Q8: Ventas por método de pago del mes (JOIN mínimo con índice)
-- SELECT pm.name, COUNT(sp.id) AS count, SUM(sp.amount) AS total
-- FROM sale_payments sp
-- JOIN payment_methods pm ON pm.id = sp.method_id
-- JOIN sales s ON s.id = sp.sale_id
-- WHERE s.store_id = ? AND s.year_month = ?
-- GROUP BY sp.method_id;

-- ──────────────────────────────────────────────────────────
-- SECCIÓN 8: MANTENIMIENTO PROGRAMADO
-- ──────────────────────────────────────────────────────────

-- Ejecutar diariamente (desde background job o al iniciar app):
-- PRAGMA wal_checkpoint(TRUNCATE);  -- Fuerza checkpoint y trunca WAL
-- PRAGMA incremental_vacuum(100);   -- Recupera 100 páginas libres
-- ANALYZE sales;                    -- Actualiza estadísticas del query planner
-- ANALYZE sale_items;
-- ANALYZE inventory;

-- Ejecutar semanalmente:
-- PRAGMA optimize;                  -- Optimizador automático SQLite
-- ANALYZE;                          -- Todas las tablas

-- Ejecutar mensualmente (fuera de horario comercial):
-- VACUUM;                           -- Desfragmentación completa (bloquea BD)
