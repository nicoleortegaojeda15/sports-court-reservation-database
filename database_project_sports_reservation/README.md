# Sports Court Reservation Database

Base de datos relacional en **Microsoft SQL Server (T-SQL)** para gestionar las reservas de pistas deportivas de un centro deportivo: clientes, empleados, deportes, pistas, tarifas, reservas, pagos y periodos de mantenimiento.

Proyecto académico individual desarrollado en inglés para la asignatura **Development of Database Applications** (Faculty of Mathematics and Physics, Charles University, Praga) durante el programa Erasmus, curso 2025/2026.

---

## Descripción

El sistema permite controlar en tiempo real la disponibilidad de las pistas de un centro deportivo. Las reglas de negocio se garantizan dentro de la propia base de datos (restricciones, triggers y procedimientos almacenados), de modo que no se pueden producir reservas solapadas, reservas durante un mantenimiento ni pagos duplicados, independientemente de la aplicación que utilice la base de datos.

### Reglas de negocio principales

- Una pista no puede tener dos reservas que se solapen en el tiempo.
- No se puede reservar una pista durante un periodo de mantenimiento, ni programar un mantenimiento sobre una reserva activa.
- Ciclo de vida de una reserva: `Pending` -> `Confirmed` -> `Completed` (o `Cancelled`).
  - `Pending`: reserva creada pero aún no pagada.
  - `Confirmed`: reserva pagada y confirmada. Un trigger la confirma automáticamente al registrar el pago.
  - Una reserva completada no se puede cancelar.
- Cada reserva admite un único pago.
- El precio se calcula según la tarifa vigente del deporte y la duración de la reserva.
- Un cliente con reservas no puede eliminarse.
- El email de cada persona es único.

---

## Modelo de datos

La base de datos consta de 10 tablas, 17 restricciones `CHECK` y 11 claves foráneas.

| Tabla | Descripción |
|---|---|
| `Person` | Datos personales comunes (nombre, apellidos, email) |
| `Customer` | Clientes del centro (especialización de `Person`) |
| `Employee` | Empleados del centro (especialización de `Person`) |
| `Sport` | Deportes disponibles (Tennis, Padel, Football, Basketball) |
| `Court` | Pistas, asociadas a un deporte |
| `Tariff` | Tarifas por deporte con periodo de validez |
| `ReservationStatus` | Estados de reserva (Pending, Confirmed, Cancelled, Completed) |
| `Reservation` | Reservas de pistas realizadas por clientes |
| `Payment` | Pagos de reservas, registrados por un empleado |
| `Maintenance` | Periodos de mantenimiento de las pistas |

---

## Objetos de la base de datos

### Triggers (4)

| Trigger | Función |
|---|---|
| `trg_reservation_no_overlap` | Impide reservas solapadas en una misma pista |
| `trg_reservation_no_maintenance` | Impide reservar durante un mantenimiento |
| `trg_maintenance_no_active_reservation` | Impide programar un mantenimiento sobre reservas activas |
| `trg_payment_confirm_reservation` | Cambia la reserva de `Pending` a `Confirmed` al registrar el pago |

### Funciones (2)

- `fn_calculate_reservation_price`: calcula el precio de una reserva según la tarifa y la duración.
- `fn_is_court_available`: indica si una pista está libre en un intervalo de tiempo.

### Procedimientos almacenados (8)

`usp_create_customer`, `usp_update_customer`, `usp_delete_customer`, `usp_create_reservation`, `usp_register_payment`, `usp_complete_reservation`, `usp_cancel_reservation`, `usp_create_maintenance`.

Incluyen validaciones con `TRY...CATCH` y errores personalizados mediante `THROW`. El borrado de clientes se ejecuta dentro de una transacción con `UPDLOCK, HOLDLOCK` para evitar condiciones de carrera.

### Vistas (8)

`vw_customer_list`, `vw_court_list`, `vw_reservation_list`, `vw_active_reservations`, `vw_pending_payments`, `vw_daily_schedule`, `vw_available_courts`, `vw_courts_under_maintenance`.

### Índices (16)

Índices sobre claves foráneas y sobre columnas de búsqueda por franja horaria (por ejemplo `IX_Reservation_court_time` e `IX_Maintenance_court_time`) para acelerar las comprobaciones de disponibilidad.

---

## Estructura del repositorio

```
.
├── 1.0-create_schema_tables.sql                 # Tablas y restricciones
├── 1.1-create_schema_triggers.sql               # Triggers
├── 1.2-create_schema_indexes.sql                # Índices
├── 1.3-create_schema_procedures_functions.sql   # Funciones y procedimientos almacenados
├── 1.4-create_schema_views.sql                  # Vistas
├── 2-insert_demo_data.sql                       # Datos de demostración
├── 3-drop_schema.sql                            # Elimina todo el esquema
└── 4-test_script.sql                            # Pruebas de las reglas de negocio
```

---

## Cómo ejecutarlo

**Requisitos:** Microsoft SQL Server y SQL Server Management Studio (SSMS) o Azure Data Studio.

1. Crea una base de datos vacía (o usa una existente) y selecciónala.
2. Ejecuta los scripts en este orden:
   1. `1.0-create_schema_tables.sql`
   2. `1.1-create_schema_triggers.sql`
   3. `1.2-create_schema_indexes.sql`
   4. `1.3-create_schema_procedures_functions.sql`
   5. `1.4-create_schema_views.sql`
   6. `2-insert_demo_data.sql`
3. Ejecuta `4-test_script.sql` para comprobar el funcionamiento.
4. Para empezar de cero, ejecuta `3-drop_schema.sql`.

---

## Pruebas

El fichero `4-test_script.sql` contiene 27 pruebas que cubren tanto casos correctos como casos que deben fallar. Algunos ejemplos:

- Cálculo de precio: 2 horas de tenis a 300 por hora dan 600.
- Comprobación de una pista libre y de una pista ocupada.
- Creación de un cliente con email duplicado: error.
- Reserva solapada con otra existente: error.
- Reserva durante un periodo de mantenimiento: error.
- Registro de un pago: la reserva pasa a `Confirmed`.
- Segundo pago sobre la misma reserva: error.
- Cancelación de una reserva completada: error.
- Mantenimiento sobre una reserva activa: error.
- Eliminación de un cliente con reservas: error.

---

## Tecnologías

- Microsoft SQL Server
- T-SQL (DDL, DML, triggers, funciones, procedimientos almacenados, vistas y transacciones)

