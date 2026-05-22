# BazarNicole — Sistema de Gestión Comercial

Aplicación de escritorio/móvil desarrollada en **Flutter** para la gestión integral de un bazar o tienda minorista. Incluye punto de venta (POS), inventario multi-tienda, compras, clientes, caja, reportes y más.

---

## Tabla de Contenidos

- [BazarNicole — Sistema de Gestión Comercial](#bazarnicole--sistema-de-gestión-comercial)
  - [Tabla de Contenidos](#tabla-de-contenidos)
  - [Descripción General](#descripción-general)
  - [Características](#características)
  - [Arquitectura](#arquitectura)
  - [Estructura del Proyecto](#estructura-del-proyecto)
  - [Base de Datos](#base-de-datos)
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
    - [Usuarios](#usuarios)
  - [Dependencias Principales](#dependencias-principales)
  - [Requisitos](#requisitos)
  - [Instalación y Ejecución](#instalación-y-ejecución)
  - [Plataformas Soportadas](#plataformas-soportadas)

---

## Descripción General

**BazarNicole** es un sistema de gestión comercial pensado para pequeñas y medianas tiendas. Corre en macOS, Windows, Linux y puede compilarse para Android/iOS. Utiliza SQLite como base de datos local, con soporte de respaldo en Google Drive.

---

## Características

- **Punto de Venta (POS)** con lectura de código de barras (cámara y escáner)
- **Gestión de Inventario** multi-tienda con análisis de vendibilidad, inversión y rotación
- **Compras a Proveedores** con seguimiento de órdenes
- **Catálogo de Productos** con imágenes, categorías y variantes
- **Gestión de Clientes** con historial de ventas y créditos
- **Gestión de Proveedores**
- **Módulo de Caja** con sesiones, movimientos, pagos y ventas a crédito
- **Reportes y Gráficas** (ventas, inventario, ROI, tendencias)
- **Usuarios y Roles** con autenticación local
- **Respaldo automático** en Google Drive
- **Exportación** a PDF, Excel (XLSX) y QR
- **Soporte multi-idioma** (español por defecto)
- **Modo escritorio** con ventana redimensionable y título personalizado

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
    ├── Services/                # Servicios (BD, autenticación, respaldo)
    ├── Utils/                   # Colores, helpers, constantes
    ├── Hooks/                   # Custom hooks de Flutter
    ├── Renders/                 # Renderizadores (PDF, reportes)
    ├── Template/                # Plantillas de UI
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
│       │   ├── database_service.dart         # Servicio principal SQLite
│       │   ├── auth_service.dart
│       │   ├── backup_service.dart
│       │   ├── google_drive_backup_service.dart
│       │   ├── drive_data_service.dart
│       │   ├── database_location_service.dart
│       │   └── session_service.dart
│       └── View/
│           ├── Auth/         # Login y rutas
│           ├── Dashboard/    # Panel principal
│           ├── POS/          # Punto de venta
│           ├── Product/      # Catálogo de productos
│           ├── Inventory/    # Inventario y análisis
│           ├── Purchases/    # Compras a proveedores
│           ├── Customers/    # Clientes y créditos
│           ├── Suppliers/    # Proveedores
│           ├── Cash/         # Módulo de caja
│           ├── Reports/      # Reportes y gráficas
│           ├── Catalog/      # Catálogo general
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
├── scripts/
│   └── build_dmg.sh          # Script para empaquetar en macOS (.dmg)
└── pubspec.yaml
```

---

## Base de Datos

Usa **SQLite** vía `sqflite` (móvil) y `sqflite_common_ffi` (escritorio). Las tablas principales son:

| Tabla                 | Descripción                                  |
| --------------------- | -------------------------------------------- |
| `stores`              | Tiendas / sucursales                         |
| `categories`          | Categorías de productos                      |
| `products`            | Catálogo de productos                        |
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

El respaldo automático se realiza hacia **Google Drive** mediante `google_drive_backup_service.dart`.

---

## Módulos

### Autenticación

- Login local con roles de usuario
- Sesiones persistentes vía `session_service.dart`

### Dashboard

- Panel de resumen con métricas clave del día
- Acceso rápido a todos los módulos

### Punto de Venta (POS)

- Búsqueda de productos por nombre o código de barras
- Escáner con cámara (`mobile_scanner`) o escáner físico
- Carrito de compra, descuentos, múltiples métodos de pago
- Emisión de recibo y QR

### Inventario

- Vista por tienda con stock actual
- **3 pestañas de análisis**: Stock | Vendibilidad | Inversión
- **Saleability Score (0–100)**: combina rotación, margen y penalización por bajo stock
- **Análisis de inversión**: `costPrice × qty`, ganancia potencial, margen %, ROI %
- Top 5 productos por ventas y por margen
- Edición de stock y transferencias entre tiendas
- Búsqueda y filtros en tiempo real

### Productos

- CRUD completo con imágenes (`image_picker`)
- Asignación de categorías
- Código de barras y QR por producto

### Compras

- Registro de órdenes de compra a proveedores
- Actualización automática de inventario al recibir mercadería

### Clientes

- Historial de compras por cliente
- Gestión de ventas a crédito y pagos de cuotas

### Proveedores

- Directorio de proveedores con datos de contacto

### Caja

- Apertura y cierre de sesión de caja
- Registro de ingresos y egresos
- Resumen del día por método de pago

### Reportes

- Ventas por período (día, semana, mes)
- Tendencia de ventas últimos 7 días
- Inversión total en inventario y ROI potencial
- Productos críticos (bajo stock + alto valor)
- Exportación a **PDF** y **Excel (XLSX)**

### Usuarios

- Gestión de cuentas con roles
- Control de acceso por módulo

---

## Dependencias Principales

| Paquete                                       | Uso                                      |
| --------------------------------------------- | ---------------------------------------- |
| `provider`                                    | Gestión de estado (ChangeNotifier)       |
| `sqflite` / `sqflite_common_ffi`              | Base de datos SQLite                     |
| `fl_chart` / `syncfusion_flutter_charts`      | Gráficas e indicadores                   |
| `syncfusion_flutter_datagrid`                 | Tablas avanzadas de datos                |
| `syncfusion_flutter_xlsio`                    | Exportación a Excel                      |
| `syncfusion_flutter_pdf` / `pdf` / `printing` | Generación e impresión de PDF            |
| `mobile_scanner`                              | Lectura de códigos de barras con cámara  |
| `qr_flutter`                                  | Generación de códigos QR                 |
| `image_picker`                                | Selección de imágenes                    |
| `google_nav_bar`                              | Barra de navegación inferior             |
| `flutter_animate`                             | Animaciones declarativas                 |
| `share_plus`                                  | Compartir archivos y contenidos          |
| `connectivity_plus`                           | Detección de conectividad de red         |
| `hive_flutter`                                | Almacenamiento clave-valor local         |
| `mailer` / `flutter_email_sender`             | Envío de correos electrónicos            |
| `dio` / `http`                                | Peticiones HTTP                          |
| `intl`                                        | Internacionalización y formato de fechas |
| `window_manager`                              | Control de ventana en escritorio         |

---

## Requisitos

- **Flutter SDK** `^3.x` (Dart `^3.8.1`)
- **Android Studio** o **Xcode** para compilar en móvil
- Para escritorio: macOS 10.14+, Windows 10+ o Linux con GTK 3

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
| Web        | ⚠️ Parcial   |
