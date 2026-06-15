# BazarNicole — Sistema de Gestión Comercial

Aplicación de escritorio/móvil/web desarrollada en **Flutter** para la gestión integral de un bazar o tienda minorista. Incluye punto de venta (POS), inventario multi-tienda, compras, clientes, caja, reportes, catálogo web público y una capa analítica OLAP empresarial.

---

## Tabla de Contenidos

- [BazarNicole — Sistema de Gestión Comercial](#bazarnicole--sistema-de-gestión-comercial)
  - [Tabla de Contenidos](#tabla-de-contenidos)
  - [Descripción General](#descripción-general)
  - [Características](#características)
  - [Arquitectura](#arquitectura)
  - [Estructura del Proyecto](#estructura-del-proyecto)
  - [Base de Datos](#base-de-datos)
    - [Tablas OLTP (operacionales)](#tablas-oltp-operacionales)
    - [Tablas OLAP (analíticas)](#tablas-olap-analíticas)
  - [Módulos](#módulos)
    - [Autenticación](#autenticación)
    - [Dashboard](#dashboard)
    - [Punto de Venta (POS)](#punto-de-venta-pos)
    - [Inventario](#inventario)
    - [Productos](#productos)
    - [Compras](#compras)
    - [Clientes](#clientes)
    - [Proveedores](#proveedores)
    - [Caja](#caja)
    - [Reportes](#reportes)
    - [Catálogo Web Público](#catálogo-web-público)
    - [Usuarios](#usuarios)
    - [Administración de BD](#administración-de-bd)
  - [Servicios Internos](#servicios-internos)
    - [AnalyticsService — Capa OLAP](#analyticsservice--capa-olap)
    - [BackgroundJobService — Jobs Asíncronos](#backgroundjobservice--jobs-asíncronos)
    - [DatabaseMaintenanceService — Mantenimiento SQLite](#databasemaintenanceservice--mantenimiento-sqlite)
    - [CatalogSyncService — Sincronización de Catálogo](#catalogsyncservice--sincronización-de-catálogo)
    - [CatalogSchedulerService — Scheduler Periódico](#catalogschedulerservice--scheduler-periódico)
    - [CatalogExportService — Exportación JSON](#catalogexportservice--exportación-json)
    - [GhPagesCatalogService — Catálogo desde GitHub Pages](#ghpagescatalogservice--catálogo-desde-github-pages)
    - [GitSyncService — Sincronización Git](#gitsyncservice--sincronización-git)
  - [Dependencias Principales](#dependencias-principales)
  - [Requisitos](#requisitos)
  - [Instalación y Ejecución](#instalación-y-ejecución)
  - [Plataformas Soportadas](#plataformas-soportadas)

---

## Descripción General

**BazarNicole** es un sistema de gestión comercial pensado para pequeñas y medianas tiendas. Corre en macOS, Windows, Linux, Android e iOS. Adicionalmente, publica un **catálogo web público** en GitHub Pages. Utiliza SQLite como base de datos local con una capa OLAP para análisis avanzados, y respalda los datos en Google Drive.

---

## Características

- **Punto de Venta (POS)** con lectura de código de barras (cámara y escáner)
- **Gestión de Inventario** multi-tienda con análisis de vendibilidad, inversión y rotación
- **Saleability Score (0–100)** basado en rotación real de ventas, margen y penalización por bajo stock
- **Compras a Proveedores** con seguimiento de órdenes
- **Catálogo de Productos** con imágenes, categorías, SKU, tags y variantes
- **Gestión de Clientes** con historial de ventas, créditos y segmentación RFM
- **Gestión de Proveedores**
- **Módulo de Caja** con sesiones, denominaciones de billetes/monedas, movimientos, pagos y ventas a crédito
- **Reportes y Gráficas** (ventas, inventario, ROI, tendencias, sparklines)
- **Catálogo Web Público** publicado en GitHub Pages, con sincronización automática cada 5 minutos
- **Usuarios y Roles** con autenticación local
- **Respaldo automático** en Google Drive (BD + imágenes)
- **Exportación** a PDF, Excel (XLSX) y QR
- **Capa OLAP** con tablas de resumen (`summary_*`, `analytics_*`) y caché analítico con TTL
- **Background Jobs** (recalcular KPIs, RFM, sparklines, mantenimiento) fuera del hilo UI
- **Mantenimiento automático de BD** (ANALYZE, vacuum incremental, WAL checkpoint cada 6 h)
- **Soporte multi-idioma** (español por defecto)
- **Modo escritorio** con ventana redimensionable y título personalizado
- **Panel de administración** de BD con consola SQL integrada

---

## Arquitectura

El proyecto sigue el patrón **MVC** adaptado a Flutter con `Provider` para la gestión de estado:

```bash
lib/
├── main.dart                    # Punto de entrada, inicialización de providers
└── Presentation/
    ├── Model/                   # Modelos de datos (entidades)
    ├── Controller/              # Lógica de negocio (ChangeNotifier)
    ├── Context/                 # Providers adicionales y registro global
    ├── View/                    # Vistas por módulo
    ├── Widgets/                 # Widgets reutilizables
    ├── Services/                # Servicios (BD, OLAP, catálogo, respaldo, git)
    ├── Utils/                   # Colores, helpers, constantes
    ├── Hooks/                   # Custom hooks de Flutter
    ├── Renders/                 # Renderizadores (PDF, responsive helper)
    ├── Template/                # Plantillas de UI (catálogo web)
    └── admin/                   # Herramientas de administración de BD
```

---

## Estructura del Proyecto

```bash
bazarnicole/
├── lib/
│   ├── main.dart
│   └── Presentation/
│       ├── Model/
│       │   ├── cash_model.dart
│       │   ├── customer_model.dart
│       │   ├── inventory_model.dart
│       │   ├── product_model.dart
│       │   ├── purchase_model.dart
│       │   ├── sale_model.dart
│       │   ├── supplier_model.dart
│       │   └── user_model.dart
│       ├── Controller/
│       │   ├── auth_provider.dart
│       │   ├── cash_controller.dart
│       │   ├── customers_controller.dart
│       │   ├── dashboard_controller.dart
│       │   ├── inventory_controller.dart
│       │   ├── pos_controller.dart
│       │   ├── product_management_controller.dart
│       │   ├── purchases_controller.dart
│       │   ├── reports_controller.dart
│       │   ├── suppliers_controller.dart
│       │   └── users_controller.dart
│       ├── Context/
│       │   ├── providers.dart           # Registro global de providers
│       │   ├── customer_provider.dart
│       │   ├── inventory_provider.dart
│       │   ├── product_provider.dart
│       │   ├── purchase_provider.dart
│       │   ├── reports_provider.dart
│       │   └── sale_provider.dart
│       ├── Services/
│       │   ├── database_service.dart              # Servicio principal SQLite (OLTP)
│       │   ├── analytics_service.dart             # Capa OLAP con caché TTL
│       │   ├── background_job_service.dart        # Motor de jobs asíncronos
│       │   ├── database_maintenance_service.dart  # Mantenimiento SQLite automático
│       │   ├── catalog_sync_service.dart          # Sincronización catálogo → Git
│       │   ├── catalog_scheduler_service.dart     # Scheduler cada 5 min
│       │   ├── catalog_export_service.dart        # Exportación JSON del catálogo
│       │   ├── gh_pages_catalog_service.dart      # Lectura catálogo GitHub Pages
│       │   ├── git_sync_service.dart              # Operaciones git (push/pull)
│       │   ├── auth_service.dart
│       │   ├── backup_service.dart
│       │   ├── google_drive_backup_service.dart
│       │   ├── drive_data_service.dart
│       │   ├── database_location_service.dart
│       │   └── session_service.dart
│       ├── Widgets/
│       │   ├── cash_widgets.dart                  # Widget de denominaciones
│       │   ├── catalog_card_widget.dart           # Tarjeta de producto del catálogo
│       │   ├── catalog_detail_widget.dart         # Detalle expandido de producto
│       │   ├── legal_page_widget.dart             # Página legal / términos
│       │   ├── inventory_widgets.dart             # Widgets del inventario analítico
│       │   ├── Inventory/                         # Widgets especializados inventario
│       │   ├── Login/                             # Widgets de login
│       │   └── POS/                               # Widgets del punto de venta
│       ├── Renders/
│       │   └── responsive_helper.dart             # Utilidades de diseño responsivo
│       ├── Template/
│       │   └── catalog_template.dart              # Plantilla visual del catálogo
│       ├── admin/
│       │   └── AdminDBPage.dart                   # Consola SQL + backup Drive
│       └── View/
│           ├── Auth/         # Login y rutas
│           ├── Login/        # Pantalla de login
│           ├── Dashboard/    # Panel principal
│           ├── POS/          # Punto de venta
│           ├── Product/      # Catálogo de productos
│           ├── Inventory/    # Inventario y análisis
│           ├── Purchases/    # Compras a proveedores
│           ├── Customers/    # Clientes y créditos
│           ├── Suppliers/    # Proveedores
│           ├── Cash/         # Módulo de caja
│           ├── Reports/      # Reportes y gráficas
│           ├── Catalog/      # Catálogo web público
│           └── Users/        # Gestión de usuarios
├── assets/
│   ├── env.txt               # Variables de entorno
│   └── database/             # Dumps SQL de referencia
├── android/
├── ios/
├── macos/
├── linux/
├── windows/
├── web/
│   ├── index.html            # Entrada web (catálogo público)
│   └── ...
├── scripts/
│   └── build_dmg.sh          # Script para empaquetar en macOS (.dmg)
└── pubspec.yaml
```

---

## Base de Datos

Usa **SQLite** vía `sqflite` (móvil) y `sqflite_common_ffi` (escritorio). Las tablas principales son:

### Tablas OLTP (operacionales)

| Tabla                 | Descripción                                  |
| --------------------- | -------------------------------------------- |
| `stores`              | Tiendas / sucursales                         |
| `categories`          | Categorías de productos                      |
| `products`            | Catálogo de productos (SKU, tags, imágenes)  |
| `inventory`           | Stock por tienda                             |
| `sales`               | Cabecera de ventas                           |
| `sale_items`          | Detalle de ítems por venta                   |
| `inventory_movements` | Movimientos de inventario (entradas/salidas) |
| `purchases`           | Órdenes de compra a proveedores              |
| `customers`           | Clientes                                     |
| `suppliers`           | Proveedores                                  |
| `users`               | Usuarios del sistema                         |
| `cash_sessions`       | Sesiones de caja (apertura/cierre)           |
| `cash_movements`      | Movimientos de caja (ingresos/egresos)       |
| `payment_methods`     | Métodos de pago disponibles                  |
| `sale_payments`       | Pagos asociados a ventas                     |
| `credit_sales`        | Ventas a crédito                             |
| `credit_payments`     | Pagos de cuotas de crédito                   |
| `purchase_items`      | Detalle de ítems por orden de compra         |

### Tablas OLAP (analíticas)

| Tabla                   | Descripción                                            |
| ----------------------- | ------------------------------------------------------ |
| `summary_sales_daily`   | Resumen de ventas por día (pre-calculado)              |
| `summary_sales_monthly` | Resumen de ventas por mes                              |
| `summary_sales_annual`  | Resumen anual de ventas                                |
| `analytics_product`     | Métricas por producto (rotación, margen, vendibilidad) |
| `analytics_cache`       | Caché de consultas OLAP con TTL configurable           |
| `kpi_snapshot`          | Snapshot de KPIs del negocio (histórico 90 días)       |
| `trend_sparklines`      | Series temporales para gráficas de tendencia           |
| `background_jobs`       | Cola de jobs asíncronos (Producer-Consumer)            |

El respaldo automático se realiza hacia **Google Drive** mediante `google_drive_backup_service.dart`.

---

## Módulos

### Autenticación

- Login local con roles de usuario
- Sesiones persistentes vía `session_service.dart`
- Pantalla de login dedicada con manejo de errores

### Dashboard

- Panel de resumen con métricas clave del día
- KPI snapshots actualizados desde la capa OLAP
- Acceso rápido a todos los módulos

### Punto de Venta (POS)

- Búsqueda de productos por nombre o código de barras
- Escáner con cámara (`mobile_scanner`) o escáner físico (`simple_barcode_scanner`)
- Carrito de compra, descuentos, múltiples métodos de pago
- Emisión de recibo y QR
- Integración con módulo de caja para registro automático de pagos

### Inventario

- Vista por tienda con stock actual
- **3 pestañas de análisis**: Stock | Vendibilidad | Inversión
- **Saleability Score (0–100)**: combina rotación real de ventas, margen y penalización por bajo stock

  ```bash
  Score = 50 + bonus_rotación(5–25) + bonus_margen(8–15) − penalización_stock(10)
  ```

- **Análisis de inversión**: `costPrice × qty`, ganancia potencial, margen %, ROI %

  ```bash
  Inversión = costPrice × quantity
  Ganancia potencial = (sellPrice − costPrice) × quantity
  Margen % = ((sellPrice − costPrice) / costPrice) × 100
  ROI % = (Total Ganancia / Total Inversión) × 100
  ```

- Top 5 productos por ventas y por margen (datos reales desde BD)
- Edición de stock y transferencias entre tiendas
- Búsqueda y filtros en tiempo real (debounce 500 ms)
- Unidades vendidas conectadas con datos reales de `sale_items`

### Productos

- CRUD completo con imágenes (`image_picker`)
- Asignación de categorías, SKU y tags
- Código de barras y QR por producto
- Vista de detalle en foto con `photo_view`

### Compras

- Registro de órdenes de compra a proveedores con ítem detallado
- Actualización automática de inventario al recibir mercadería

### Clientes

- Historial de compras por cliente
- Gestión de ventas a crédito y pagos de cuotas
- **Segmentación RFM** (Recency, Frequency, Monetary) calculada por `BackgroundJobService`

### Proveedores

- Directorio de proveedores con datos de contacto

### Caja

- Apertura y cierre de sesión de caja
- **Widget de denominaciones**: entrada de billetes y monedas con total en tiempo real
- Registro de ingresos y egresos
- Resumen del día por método de pago
- Integración con ventas a crédito

### Reportes

- Ventas por período (día, semana, mes) — datos desde tablas `summary_*`
- Tendencia de ventas últimos 7 días con sparklines
- Inversión total en inventario y ROI potencial
- Productos críticos (bajo stock + alto valor)
- Exportación a **PDF** y **Excel (XLSX)**
- Generación completa en paralelo vía `ReportsProvider.generateFullReport()`

### Catálogo Web Público

- Vitrina web pública accesible desde cualquier navegador (GitHub Pages)
- Categorías: **Bazar** y **Papelería** con pestañas
- Búsqueda de productos en tiempo real
- Imágenes cargadas directamente desde Google Drive
- Autenticación silenciosa con Google Sign-In para cargar datos
- **Sincronización automática** cada 5 minutos desde la app de escritorio
  - Proceso: Hash de datos → Exportación JSON → Git commit + push
  - Solo sincroniza si los datos cambiaron (comparación SHA-256)
  - Log de sincronización en archivo `catalog_sync.log`
- Soporte para catálogo paginado (lectura desde `GhPagesCatalogService`)
- Página legal / términos integrada

### Usuarios

- Gestión de cuentas con roles
- Control de acceso por módulo

### Administración de BD

- **AdminDBPage**: consola SQL interactiva para ejecutar consultas directas
- Visualización de resultados en tabla scrolleable
- Backup manual a Google Drive con progreso en tiempo real
- Acceso a la ruta real de la base de datos mediante `DatabaseLocationService`
- Compartir el archivo de BD vía `share_plus`

---

## Servicios Internos

### AnalyticsService — Capa OLAP

Singleton que actúa como capa de lectura OLAP. **Nunca ejecuta JOINs masivos en el hilo principal**.

- Lee exclusivamente tablas `summary_*` y `analytics_*`
- Gestiona `analytics_cache` con TTL configurable (1 min KPIs / 5 min default / 15 min reportes)
- Usa `Isolate` para cómputos pesados fuera del hilo UI
- Provee KPI snapshots, sparklines y rankings de productos

### BackgroundJobService — Jobs Asíncronos

Motor Producer-Consumer sobre la tabla `background_jobs`. Ejecuta jobs con un timer cada 30 segundos.

| Job                        | Descripción                              |
| -------------------------- | ---------------------------------------- |
| `recalculate_daily`        | Recalcula `summary_sales_daily`          |
| `recalculate_monthly`      | Recalcula `summary_sales_monthly`        |
| `recalculate_annual`       | Recalcula `summary_sales_annual`         |
| `rebuild_kpi`              | Reconstruye `kpi_snapshot`               |
| `update_rfm`               | Actualiza segmentos RFM de clientes      |
| `refresh_analytics_product`| Recalcula `analytics_product`            |
| `update_sparklines`        | Actualiza `trend_sparklines`             |
| `maintenance`              | ANALYZE + vacuum incremental + checkpoint|

### DatabaseMaintenanceService — Mantenimiento SQLite

Mantenimiento automático cada 6 horas sin bloquear la UI.

- **ANALYZE** de tablas críticas (actualiza estadísticas del query planner)
- **Incremental VACUUM** (128 páginas × 4 KB ≈ 512 KB por ciclo)
- **WAL checkpoint** PASSIVE → FULL → TRUNCATE según umbral de páginas
- Limpieza de `analytics_cache` expirado
- Limpieza de jobs obsoletos (retención 7 días)
- Limpieza de snapshots KPI antiguos (retención 90 días)
- `PRAGMA quick_check` para verificación de integridad
- Reporte de métricas de salud de la BD

### CatalogSyncService — Sincronización de Catálogo

Sincroniza el catálogo de productos hacia el repositorio git para publicación en GitHub Pages.

- Exporta productos activos a JSON (`products.json`, `categories.json`, `manifest.json`)
- Calcula hash SHA-256 del catálogo para evitar sincronizaciones innecesarias
- Ejecuta `git add`, `git commit`, `git push` vía `GitSyncService`
- Mantiene log de sincronización en `catalog_sync.log`
- Estados: `idle` | `hashing` | `exporting` | `pushing` | `success` | `error` | `skipped`

### CatalogSchedulerService — Scheduler Periódico

Singleton que programa sincronizaciones automáticas del catálogo.

- Intervalo configurable (por defecto **5 minutos**)
- Primera sincronización inmediata al arrancar
- Métodos: `start()`, `stop()`, `restart()`

### CatalogExportService — Exportación JSON

Genera los archivos JSON del catálogo para la vitrina web.

- `CatalogProductJson`: solo expone campos públicos (precio, descripción, URLs de Drive, categoría, stock total)
- Soporte de paginación para catálogos grandes
- `manifest.json` con versión, fecha y contadores

### GhPagesCatalogService — Catálogo desde GitHub Pages

Lectura del catálogo publicado en GitHub Pages desde la app (o desde web).

- `GhPagesManifest`: versión, fecha, contadores, soporte de paginación
- `GhPagesProduct`: modelo completo del producto público
- Detección automática de catálogos paginados

### GitSyncService — Sincronización Git

Abstracción sobre operaciones git para el flujo de publicación del catálogo.

- Ejecuta `git add`, `commit`, `push`, `pull` como procesos del sistema
- `GitOperationResult`: resultado tipado con stdout, stderr y código de salida
- `GitSyncLogEntry`: log estructurado de operaciones con timestamp

---

## Dependencias Principales

| Paquete                                       | Uso                                              |
| --------------------------------------------- | ------------------------------------------------ |
| `provider`                                    | Gestión de estado (ChangeNotifier)               |
| `sqflite` / `sqflite_common_ffi`              | Base de datos SQLite (móvil y escritorio)        |
| `drift`                                       | ORM adicional para consultas tipadas             |
| `fl_chart` / `syncfusion_flutter_charts`      | Gráficas, sparklines e indicadores               |
| `syncfusion_flutter_datagrid`                 | Tablas avanzadas de datos                        |
| `syncfusion_flutter_xlsio`                    | Exportación a Excel                              |
| `syncfusion_flutter_pdf` / `pdf` / `printing` | Generación e impresión de PDF                    |
| `mobile_scanner` / `simple_barcode_scanner`   | Lectura de códigos de barras                     |
| `qr_flutter`                                  | Generación de códigos QR                         |
| `image_picker`                                | Selección de imágenes                            |
| `photo_view`                                  | Visualización de imágenes en pantalla completa   |
| `google_nav_bar`                              | Barra de navegación inferior                     |
| `flutter_animate`                             | Animaciones declarativas                         |
| `share_plus`                                  | Compartir archivos y contenidos                  |
| `file_picker`                                 | Selección de archivos del sistema                |
| `connectivity_plus`                           | Detección de conectividad de red                 |
| `hive_flutter` / `hive`                       | Almacenamiento clave-valor local                 |
| `sembast`                                     | Base de datos NoSQL local adicional              |
| `mailer` / `flutter_email_sender`             | Envío de correos electrónicos                    |
| `dio` / `http`                                | Peticiones HTTP                                  |
| `google_sign_in` / `googleapis`               | Autenticación Google y API de Drive              |
| `crypto`                                      | Hash SHA-256 para sincronización de catálogo     |
| `intl`                                        | Internacionalización y formato de fechas         |
| `window_manager`                              | Control de ventana en escritorio                 |
| `url_launcher`                                | Abrir URLs externas                              |
| `infinite_scroll_pagination`                  | Paginación infinita en listas                    |
| `auto_size_text`                              | Texto con auto-ajuste de tamaño                  |
| `flutter_speed_dial`                          | Botón de acción flotante con sub-acciones        |
| `data_table_2`                                | Tablas de datos avanzadas adicionales            |
| `tutorial_coach_mark`                         | Tutoriales y onboarding interactivo              |
| `emoji_picker_flutter`                        | Selector de emojis                               |
| `webview_flutter`                             | WebView integrado                                |
| `flutter_multi_formatter`                     | Formateadores de texto (teléfonos, moneda, etc.) |
| `open_file`                                   | Abrir archivos con la aplicación del sistema     |

---

## Requisitos

- **Flutter SDK** `^3.x` (Dart `^3.8.1`)
- **Android Studio** o **Xcode** para compilar en móvil
- Para escritorio: macOS 10.14+, Windows 10+ o Linux con GTK 3
- **Git** instalado y configurado en el sistema (necesario para sincronización del catálogo web)
- Cuenta de **Google** con acceso a Drive (para respaldo y catálogo web)

---

## Instalación y Ejecución

```bash
# 1. Clonar el repositorio
git clone https://github.com/ceciliamoreno044-droid/bazarnicole.git
cd bazarnicole

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar en modo debug
flutter run

# 4. Ejecutar en una plataforma específica
flutter run -d macos
flutter run -d windows
flutter run -d android
```

Para generar un instalador `.dmg` en macOS:

```bash
bash scripts/build_dmg.sh
```

---

## Plataformas Soportadas

| Plataforma | Estado       |
| ---------- | ------------ |
| macOS      | ✅ Soportado |
| Windows    | ✅ Soportado |
| Linux      | ✅ Soportado |
| Android    | ✅ Soportado |
| iOS        | ✅ Soportado |
| Web        | ✅GitHubPages|
