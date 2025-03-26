Proyecto de Gestión de Base de Datos "Ventas"
Este documento describe los ejercicios realizados en el proyecto de gestión de la base de datos "Ventas". A continuación, se detalla cada uno de los ejercicios ejecutados, junto con su propósito y funcionalidad.

Ejercicio 1: Respaldo Completo de la Base de Datos
![image](https://github.com/user-attachments/assets/8bf17460-1a70-49d1-9a0b-1921a02eb106)



Descripción: Se realizó un respaldo completo de la base de datos "Ventas" y se guardó en la ruta especificada. Este respaldo permite restaurar la base de datos en caso de pérdida de datos.

Ejercicio 2: Creación de Usuarios y Roles
![image](https://github.com/user-attachments/assets/fccb3c20-ca70-441b-b283-ebd5cffad994)

Descripción: Se crearon dos usuarios (Cepeda y Wortley) con contraseñas específicas y se les asignaron roles de servidor que les otorgan permisos para crear bases de datos y administrar el servidor.

Ejercicio 3: Procedimientos de Respaldo

![image](https://github.com/user-attachments/assets/4374a160-46e2-4d76-a12f-a81df917560b)

Descripción: Se implementaron procedimientos almacenados para realizar respaldos completos, diferenciales y de logs de la base de datos "Ventas". Estos procedimientos permiten automatizar el proceso de respaldo y facilitar la gestión de la base de datos.

Ejercicio 4: Auditoría de Cambios en la Base de Datos
![image](https://github.com/user-attachments/assets/70a668a5-d0a6-4b36-aeca-284273b04ae1)

Descripción: Se creó un esquema de auditoría y una tabla para registrar eventos de creación y eliminación de tablas en la base de datos. Se implementó un trigger que registra automáticamente estos eventos, lo que permite llevar un control de cambios en la estructura de la base de datos.

Ejercicio 5: Configuración de Replicación
![image](https://github.com/user-attachments/assets/1a6e6678-81d3-40b5-9eda-a352cd0b11a5)

Descripción: Se configuró la replicación de la base de datos "Ventas" para permitir la sincronización de datos entre diferentes servidores. Se crearon publicaciones y artículos que especifican qué datos se replicarán.

Ejercicio 6: Restauración de la Base de Datos
![image](https://github.com/user-attachments/assets/d2da7e1a-a364-43a5-b741-777af1c74d73)

Descripción: Se realizaron operaciones de restauración de la base de datos "Ventas" utilizando los respaldos previamente creados. Esto permite recuperar la base de datos a un estado anterior en caso de ser necesario.

