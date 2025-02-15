BACKUP DATABASE [Ventas] TO  DISK = N'C:\IEFI\Backups\Ventas-BackupFull' WITH  DESCRIPTION = N'Ventas-Full Database Backup', NOFORMAT, NOINIT,  NAME = N'Ventas-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO


--2--

CREATE LOGIN Cepeda WITH PASSWORD=N'1234', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
CREATE LOGIN Wortley WITH PASSWORD=N'1234', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
ALTER SERVER ROLE [dbcreator] ADD MEMBER [Cepeda]
GO
ALTER SERVER ROLE [serveradmin] ADD MEMBER [Cepeda]
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [Cepeda]
GO

ALTER SERVER ROLE [dbcreator] ADD MEMBER [Wortley]
GO
ALTER SERVER ROLE [serveradmin] ADD MEMBER [Wortley]
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [Wortley]
GO


/****** Object:  ServerRole [DBA]  */
CREATE SERVER ROLE [DBA]
GO

ALTER SERVER ROLE [serveradmin] ADD MEMBER [DBA]
GO

ALTER SERVER ROLE [dbcreator] ADD MEMBER [DBA]
GO


--USUARIOS BASE DE DATOS---
USE [Ventas]
GO
CREATE USER [Wortley] FOR LOGIN [Wortley]
GO
USE [Ventas]
GO
ALTER ROLE [db_datareader] ADD MEMBER [Wortley]
GO
USE [Ventas]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [Wortley]
GO
USE [Ventas]
GO
ALTER ROLE [db_owner] ADD MEMBER [Wortley]
GO

USE [Ventas]
GO
CREATE USER [Cepeda] FOR LOGIN [Cepeda]
GO
USE [Ventas]
GO
ALTER ROLE [db_datareader] ADD MEMBER [Cepeda]
GO
USE [Ventas]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [Cepeda]
GO
USE [Ventas]
GO
ALTER ROLE [db_owner] ADD MEMBER [Cepeda]
GO


/****** Object:  DatabaseRole [DESA] */
CREATE ROLE [DESA]
GO

--3--
BACKUP DATABASE [Ventas] TO DISK = 'C:\IEFI\Backups\BackupFull.bak' WITH INIT;

use master
EXEC dbo.CopiaRespaldoFull

BACKUP DATABASE [Ventas]TO DISK = 'C:\IEFI\Backups\BackupDif.bak' WITH DIFFERENTIAL, INIT;

USE master
EXEC dbo.CopiaRespaldoDif

BACKUP LOG [Ventas]TO DISK = 'C:\IEFI\Backups\BackupLog.bak' WITH INIT;

use master
EXEC dbo.CopiaRespaldoLog


-- Habilitar configuración avanzada
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

-- Habilitar xp_cmdshell
EXEC sp_configure 'xp_cmdshell', 1;
GO
RECONFIGURE;
GO


use master
GO 

CREATE PROCEDURE dbo.CopiaRespaldoFull
AS
BEGIN
    SET NOCOUNT ON;
DECLARE @sourcePath NVARCHAR(255) = 'C:\IEFI\Backups\BackupFull.bak';
DECLARE @destinationPath NVARCHAR(255) = 'C:\IEFI\BackupsNube\BackupFullREP.bak';

-- Crear el comando de copia
DECLARE @cmd NVARCHAR(512);
SET @cmd = 'COPY "' + @sourcePath + '" "' + @destinationPath + '"';

-- Ejecutar el comando de copia
EXEC xp_cmdshell @cmd;

END;
GO

CREATE PROCEDURE dbo.CopiaRespaldoDif
AS
BEGIN
    SET NOCOUNT ON;
DECLARE @sourcePath NVARCHAR(255) = 'C:\IEFI\Backups\BackupDif.bak';
DECLARE @destinationPath NVARCHAR(255) = 'C:\IEFI\BackupsNube\BackupDifREP.bak';

-- Crear el comando de copia
DECLARE @cmd NVARCHAR(512);
SET @cmd = 'COPY "' + @sourcePath + '" "' + @destinationPath + '"';

-- Ejecutar el comando de copia
EXEC xp_cmdshell @cmd;

END;
GO

CREATE PROCEDURE dbo.CopiaRespaldoLog
AS
BEGIN
    SET NOCOUNT ON;
DECLARE @sourcePath NVARCHAR(255) = 'C:\IEFI\Backups\BackupLog.bak';
DECLARE @destinationPath NVARCHAR(255) = 'C:\IEFI\BackupsNube\BackupLogREP.bak';

-- Crear el comando de copia
DECLARE @cmd NVARCHAR(512);
SET @cmd = 'COPY "' + @sourcePath + '" "' + @destinationPath + '"';

-- Ejecutar el comando de copia
EXEC xp_cmdshell @cmd;

END;
GO


USE Ventas;
GO
exec sp_TableroVentasMay

exec sp_TableroVentasMin

--4--	

CREATE SCHEMA audit;
GO

CREATE TABLE audit.LogAuditoria (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Usuario NVARCHAR(128),
    FechaHora DATETIME,
    TipoEvento NVARCHAR(50),
    ObjetoAfectado NVARCHAR(128),
    SentenciaRealizada NVARCHAR(MAX),
    Detalle XML

);
GO

USE [Ventas]
GO

/****** Object:  DdlTrigger [trg_AuditTable]    Script Date: 13/06/2024 14:13:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
--trigger
CREATE TRIGGER [trg_AuditTable]
ON DATABASE
FOR CREATE_TABLE, DROP_TABLE
AS
BEGIN

	
    DECLARE @data XML = EVENTDATA();
    DECLARE @usuario NVARCHAR(128) = SUSER_SNAME();
    DECLARE @fechaHora DATETIME = GETDATE();
    DECLARE @tipoEvento NVARCHAR(50) = @data.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(50)');
    DECLARE @objetoAfectado NVARCHAR(128) = @data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)');
    DECLARE @sentenciaRealizada NVARCHAR(MAX) = @data.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)');
    DECLARE @detalle XML = @data;
    
	if @objetoAfectado IN ('TableroMin', 'TableroMay')
    INSERT INTO audit.LogAuditoria (Usuario, FechaHora, TipoEvento, ObjetoAfectado, SentenciaRealizada, Detalle)
    VALUES (@usuario, @fechaHora, @tipoEvento, @objetoAfectado, @sentenciaRealizada, @detalle);

END;
GO

ENABLE TRIGGER [trg_AuditTable] ON DATABASE
GO

exec dbo.sp_TableroMay
exec dbo.sp_TableroMin

use Ventas

select * from audit.LogAuditoria

USE master;
GO

use Ventas

exec dbo.sp_TableroMin



EXEC dbo.CopiaRespaldoLog

EXEC dbo.CopiaRespaldoFull

EXEC dbo.CopiaRespaldoDif

CREATE TABLE [dbo].[TableroMin](
	[Año] [int] NULL,
	[Enero] [money] NULL,
	[Febrero] [money] NULL,
	[Marzo] [money] NULL,
	[Abril] [money] NULL,
	[Mayo] [money] NULL,
	[Junio] [money] NULL,
	[Julio] [money] NULL,
	[Agosto] [money] NULL,
	[Septiembre] [money] NULL,
	[Octubre] [money] NULL,
	[Noviembre] [money] NULL,
	[Diciembre] [money] NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[TableroMay](
	[Año] [int] NULL,
	[Enero] [money] NULL,
	[Febrero] [money] NULL,
	[Marzo] [money] NULL,
	[Abril] [money] NULL,
	[Mayo] [money] NULL,
	[Junio] [money] NULL,
	[Julio] [money] NULL,
	[Agosto] [money] NULL,
	[Septiembre] [money] NULL,
	[Octubre] [money] NULL,
	[Noviembre] [money] NULL,
	[Diciembre] [money] NULL
) ON [PRIMARY]
GO

INSERT INTO [dbo].[TableroMay] (Año, Enero, Febrero, Marzo, Abril, Mayo, Junio, Julio, Agosto, Septiembre, Octubre, Noviembre, Diciembre)
SELECT Año, Enero, Febrero, Marzo, Abril, Mayo, Junio, Julio, Agosto, Septiembre, Octubre, Noviembre, Diciembre
FROM [dbo].[TableroVentasMay]
GO

INSERT INTO [dbo].[TableroMin] (Año, Enero, Febrero, Marzo, Abril, Mayo, Junio, Julio, Agosto, Septiembre, Octubre, Noviembre, Diciembre)
SELECT Año, Enero, Febrero, Marzo, Abril, Mayo, Junio, Julio, Agosto, Septiembre, Octubre, Noviembre, Diciembre
FROM [dbo].[TableroVentasMin]
GO

-- Verificar los datos en TableroMay
SELECT * FROM [dbo].[TableroMay]
GO

use Ventas

select * from audit.LogAuditoria


--5---

--Categoria--
use master
exec sp_replicationdboption @dbname = N'Ventas', @optname = N'publish', @value = N'true'
GO

-- Adding the snapshot publication
use [Ventas]
exec sp_addpublication @publication = N'PubliCategoria', @description = N'Snapshot publication of database ''Ventas'' from Publisher ''Pc-Santiw\MSQLDEVELOPER''.', @sync_method = N'native', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'snapshot', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1
GO


exec sp_addpublication_snapshot @publication = N'PubliCategoria', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
exec sp_grant_publication_access @publication = N'PubliCategoria', @login = N'sa'
GO
exec sp_grant_publication_access @publication = N'PubliCategoria', @login = N'Pc-Santiw\sanwo'
GO
exec sp_grant_publication_access @publication = N'PubliCategoria', @login = N'NT SERVICE\SQLAgent$MSQLDEVELOPER'
GO
exec sp_grant_publication_access @publication = N'PubliCategoria', @login = N'NT Service\MSSQL$MSQLDEVELOPER'
GO
exec sp_grant_publication_access @publication = N'PubliCategoria', @login = N'NT SERVICE\Winmgmt'
GO
exec sp_grant_publication_access @publication = N'PubliCategoria', @login = N'NT SERVICE\SQLWriter'
GO
exec sp_grant_publication_access @publication = N'PubliCategoria', @login = N'Wortley'
GO
exec sp_grant_publication_access @publication = N'PubliCategoria', @login = N'Cepeda'
GO
exec sp_grant_publication_access @publication = N'PubliCategoria', @login = N'distributor_admin'
GO

-- Adding the snapshot articles
use [Ventas]
exec sp_addarticle @publication = N'PubliCategoria', @article = N'articulos', @source_owner = N'dbo', @source_object = N'articulos', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509D, @identityrangemanagementoption = N'none', @destination_table = N'articulos', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'true', @ins_cmd = N'SQL', @del_cmd = N'SQL', @upd_cmd = N'SQL', @filter_clause = N'[estado]=''D'''

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'PubliCategoria', @article = N'articulos', @column = N'articulo', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'PubliCategoria', @article = N'articulos', @column = N'marca', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'PubliCategoria', @article = N'articulos', @column = N'rubro', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'PubliCategoria', @article = N'articulos', @column = N'nombre', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'PubliCategoria', @article = N'articulos', @column = N'preciomenor', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'PubliCategoria', @article = N'articulos', @column = N'promocion', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article filter
exec sp_articlefilter @publication = N'PubliCategoria', @article = N'articulos', @filter_name = N'FLTR_articulos_1__78', @filter_clause = N'[estado]=''D''', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article synchronization object
exec sp_articleview @publication = N'PubliCategoria', @article = N'articulos', @view_name = N'SYNC_articulos_1__78', @filter_clause = N'[estado]=''D''', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO
use [Ventas]
exec sp_addarticle @publication = N'PubliCategoria', @article = N'marcas', @source_owner = N'dbo', @source_object = N'marcas', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509D, @identityrangemanagementoption = N'none', @destination_table = N'marcas', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'SQL', @del_cmd = N'SQL', @upd_cmd = N'SQL'
GO
use [Ventas]
exec sp_addarticle @publication = N'PubliCategoria', @article = N'rubros', @source_owner = N'dbo', @source_object = N'rubros', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509D, @identityrangemanagementoption = N'none', @destination_table = N'rubros', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'SQL', @del_cmd = N'SQL', @upd_cmd = N'SQL'
GO

-- Adding the snapshot subscriptions
use [Ventas]
exec sp_addsubscription @publication = N'PubliCategoria', @subscriber = N'PC-SANTIW\MSQLEXPRESS', @destination_db = N'Catalogo', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'PubliCategoria', @subscriber = N'PC-SANTIW\MSQLEXPRESS', @subscriber_db = N'Catalogo', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'
GO

--Monitor--

-- Enabling the replication database
use master
exec sp_replicationdboption @dbname = N'Ventas', @optname = N'publish', @value = N'true'
GO

-- Adding the snapshot publication
use [Ventas]
exec sp_addpublication @publication = N'PubliMonitor', @description = N'Snapshot publication of database ''Ventas'' from Publisher ''Pc-Santiw\MSQLDEVELOPER''.', @sync_method = N'native', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'snapshot', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1
GO


exec sp_addpublication_snapshot @publication = N'PubliMonitor', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 0, @publisher_login = N'Wortley', @publisher_password = N''
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'sa'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'Pc-Santiw\sanwo'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'NT SERVICE\SQLAgent$MSQLDEVELOPER'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'NT Service\MSSQL$MSQLDEVELOPER'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'NT SERVICE\Winmgmt'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'NT SERVICE\SQLWriter'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'Wortley'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'Cepeda'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'distributor_admin'
GO

-- Adding the snapshot articles
use [Ventas]
exec sp_addarticle @publication = N'PubliMonitor', @article = N'TableroVentasMay', @source_owner = N'dbo', @source_object = N'TableroVentasMay', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509D, @identityrangemanagementoption = N'none', @destination_table = N'TableroVentasMay', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'SQL', @del_cmd = N'SQL', @upd_cmd = N'SQL'
GO
use [Ventas]
exec sp_addarticle @publication = N'PubliMonitor', @article = N'TableroVentasMin', @source_owner = N'dbo', @source_object = N'TableroVentasMin', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509D, @identityrangemanagementoption = N'none', @destination_table = N'TableroVentasMin', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'SQL', @del_cmd = N'SQL', @upd_cmd = N'SQL'
GO

-- Adding the snapshot subscriptions
use [Ventas]
exec sp_addsubscription @publication = N'PubliMonitor', @subscriber = N'PC-SANTIW\MSQLEXPRESS', @destination_db = N'Monitor', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'PubliMonitor', @subscriber = N'PC-SANTIW\MSQLEXPRESS', @subscriber_db = N'Monitor', @job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'Wortley', @subscriber_password = null, @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'
GO



--Pasos replica

/****** Scripting replication configuration. Script Date: 14/6/2024 13:53:27 ******/
/****** Please Note: For security reasons, all password parameters were scripted with either NULL or an empty string. ******/

/****** Begin: Script to be run at Publisher ******/

/****** Installing the server as a Distributor. Script Date: 14/6/2024 13:53:27 ******/
use master
exec sp_adddistributor @distributor = N'PC-SANTIW\MSQLDEVELOPER', @password = N''
GO

-- Adding the agent profiles
-- Updating the agent profile defaults
exec sp_MSupdate_agenttype_default @profile_id = 1
GO
exec sp_MSupdate_agenttype_default @profile_id = 2
GO
exec sp_MSupdate_agenttype_default @profile_id = 4
GO
exec sp_MSupdate_agenttype_default @profile_id = 6
GO
exec sp_MSupdate_agenttype_default @profile_id = 11
GO

-- Adding the distribution databases
use master
exec sp_adddistributiondb @database = N'distribution', @data_folder = N'C:\IEFI\Replicas\Distribuidor', @data_file = N'distribution.MDF', @data_file_size = 13, @log_folder = N'C:\IEFI\Replicas\Distribuidor', @log_file = N'distribution.LDF', @log_file_size = 9, @min_distretention = 0, @max_distretention = 72, @history_retention = 48, @deletebatchsize_xact = 5000, @deletebatchsize_cmd = 2000, @security_mode = 1
GO

-- Adding the distribution publishers
exec sp_adddistpublisher @publisher = N'PC-SANTIW\MSQLDEVELOPER', @distribution_db = N'distribution', @security_mode = 0, @login = N'Wortley', @password = N'', @working_directory = N'C:\IEFI\Replicas\Distribuidor', @trusted = N'false', @thirdparty_flag = 0, @publisher_type = N'MSSQLSERVER'
GO

exec sp_addsubscriber @subscriber = N'PC-SANTIW\MSQLEXPRESS', @type = 0, @description = N''
GO


/****** End: Script to be run at Publisher ******/


-- Enabling the replication database
use master
exec sp_replicationdboption @dbname = N'Ventas', @optname = N'publish', @value = N'true'
GO

exec [Ventas].sys.sp_addlogreader_agent @job_login = null, @job_password = null, @publisher_security_mode = 1
GO
exec [Ventas].sys.sp_addqreader_agent @job_login = null, @job_password = null, @frompublisher = 1
GO
-- Adding the snapshot publication
use [Ventas]
exec sp_addpublication @publication = N'Catalogo', @description = N'Snapshot publication of database ''Ventas'' from Publisher ''Pc-Santiw\MSQLDEVELOPER''.', @sync_method = N'native', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'snapshot', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1
GO


exec sp_addpublication_snapshot @publication = N'Catalogo', @frequency_type = 4, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 30, @active_start_time_of_day = 83000, @active_end_time_of_day = 213000, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 0, @publisher_login = N'Wortley', @publisher_password = N''
exec sp_grant_publication_access @publication = N'Catalogo', @login = N'sa'
GO
exec sp_grant_publication_access @publication = N'Catalogo', @login = N'Pc-Santiw\sanwo'
GO
exec sp_grant_publication_access @publication = N'Catalogo', @login = N'NT SERVICE\SQLAgent$MSQLDEVELOPER'
GO
exec sp_grant_publication_access @publication = N'Catalogo', @login = N'NT Service\MSSQL$MSQLDEVELOPER'
GO
exec sp_grant_publication_access @publication = N'Catalogo', @login = N'NT SERVICE\Winmgmt'
GO
exec sp_grant_publication_access @publication = N'Catalogo', @login = N'NT SERVICE\SQLWriter'
GO
exec sp_grant_publication_access @publication = N'Catalogo', @login = N'Wortley'
GO
exec sp_grant_publication_access @publication = N'Catalogo', @login = N'Cepeda'
GO
exec sp_grant_publication_access @publication = N'Catalogo', @login = N'distributor_admin'
GO

-- Adding the snapshot articles
use [Ventas]
exec sp_addarticle @publication = N'Catalogo', @article = N'articulos', @source_owner = N'dbo', @source_object = N'articulos', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509D, @identityrangemanagementoption = N'none', @destination_table = N'articulos', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'true', @ins_cmd = N'SQL', @del_cmd = N'SQL', @upd_cmd = N'SQL', @filter_clause = N'[estado]= ''D'''

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'Catalogo', @article = N'articulos', @column = N'articulo', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Catalogo', @article = N'articulos', @column = N'marca', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Catalogo', @article = N'articulos', @column = N'rubro', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Catalogo', @article = N'articulos', @column = N'nombre', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Catalogo', @article = N'articulos', @column = N'preciomenor', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Catalogo', @article = N'articulos', @column = N'promocion', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article filter
exec sp_articlefilter @publication = N'Catalogo', @article = N'articulos', @filter_name = N'FLTR_articulos_1__55', @filter_clause = N'[estado]= ''D''', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article synchronization object
exec sp_articleview @publication = N'Catalogo', @article = N'articulos', @view_name = N'SYNC_articulos_1__55', @filter_clause = N'[estado]= ''D''', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO
use [Ventas]
exec sp_addarticle @publication = N'Catalogo', @article = N'marcas', @source_owner = N'dbo', @source_object = N'marcas', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509D, @identityrangemanagementoption = N'none', @destination_table = N'marcas', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'SQL', @del_cmd = N'SQL', @upd_cmd = N'SQL'
GO
use [Ventas]
exec sp_addarticle @publication = N'Catalogo', @article = N'rubros', @source_owner = N'dbo', @source_object = N'rubros', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509D, @identityrangemanagementoption = N'none', @destination_table = N'rubros', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'SQL', @del_cmd = N'SQL', @upd_cmd = N'SQL'
GO

-- Adding the snapshot subscriptions
use [Ventas]
exec sp_addsubscription @publication = N'Catalogo', @subscriber = N'PC-SANTIW\MSQLEXPRESS', @destination_db = N'CatalogoIEFI', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'Catalogo', @subscriber = N'PC-SANTIW\MSQLEXPRESS', @subscriber_db = N'CatalogoIEFI', @job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'Wortley', @subscriber_password = null, @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'
GO

-- Adding the snapshot publication
use [Ventas]
exec sp_addpublication @publication = N'PubliMonitor', @description = N'Snapshot publication of database ''Ventas'' from Publisher ''Pc-Santiw\MSQLDEVELOPER''.', @sync_method = N'native', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'snapshot', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1
GO


exec sp_addpublication_snapshot @publication = N'PubliMonitor', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 0, @publisher_login = N'Wortley', @publisher_password = N''
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'sa'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'Pc-Santiw\sanwo'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'NT SERVICE\SQLAgent$MSQLDEVELOPER'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'NT Service\MSSQL$MSQLDEVELOPER'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'NT SERVICE\Winmgmt'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'NT SERVICE\SQLWriter'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'Wortley'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'Cepeda'
GO
exec sp_grant_publication_access @publication = N'PubliMonitor', @login = N'distributor_admin'
GO

-- Adding the snapshot articles
use [Ventas]
exec sp_addarticle @publication = N'PubliMonitor', @article = N'TableroVentasMay', @source_owner = N'dbo', @source_object = N'TableroVentasMay', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509D, @identityrangemanagementoption = N'none', @destination_table = N'TableroVentasMay', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'SQL', @del_cmd = N'SQL', @upd_cmd = N'SQL'
GO
use [Ventas]
exec sp_addarticle @publication = N'PubliMonitor', @article = N'TableroVentasMin', @source_owner = N'dbo', @source_object = N'TableroVentasMin', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509D, @identityrangemanagementoption = N'none', @destination_table = N'TableroVentasMin', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'SQL', @del_cmd = N'SQL', @upd_cmd = N'SQL'
GO

-- Adding the snapshot subscriptions
use [Ventas]
exec sp_addsubscription @publication = N'PubliMonitor', @subscriber = N'PC-SANTIW\MSQLEXPRESS', @destination_db = N'Monitor', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'PubliMonitor', @subscriber = N'PC-SANTIW\MSQLEXPRESS', @subscriber_db = N'Monitor', @job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'Wortley', @subscriber_password = null, @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'
GO
use [Ventas]
exec sp_addsubscription @publication = N'PubliMonitor', @subscriber = N'PC-SANTIW\MSQLEXPRESS', @destination_db = N'MonitorIEFI', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'PubliMonitor', @subscriber = N'PC-SANTIW\MSQLEXPRESS', @subscriber_db = N'MonitorIEFI', @job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'Wortley', @subscriber_password = null, @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'
GO






--6--

USE [master]
RESTORE DATABASE [Ventas] FROM  DISK = N'C:\IEFI\Backups\BackupFull.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5
RESTORE DATABASE [Ventas] FROM  DISK = N'C:\IEFI\Backups\BackupDif.bak' WITH  DIFFERENTIAL,NOUNLOAD,  STATS = 5
RESTORE LOG [Ventas] FROM  DISK = N'C:\IEFI\Backups\BackupLog.bak' WITH NOFORMAT,  NOUNLOAD ,  STATS = 5


GO




select * from art