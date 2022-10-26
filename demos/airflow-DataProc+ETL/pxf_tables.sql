create readable external table pxf_s3_sensors(
	deviceid text, 
	seconds_counter int, 
	message_id int, 
	accel_pedal_position int, 
	altitude float, 
	battery_voltage float, 
	brake_pedal_position int, 
	cabin_temperature smallint,
	course smallint, 
	engine_oil_life smallint,
	engine_speed smallint,
	fuel_level int, 
	gear_lever_position int, 
	heading smallint,
	latitude float,
	longitude float,
	odometer int,
	power_pack_status smallint,
	satqty smallint,
	speed smallint,
	tcu_common_datetime timestamp,
	total_operation_hours int)
LOCATION('pxf://{S3_BUCKET}/{FILE_NAME_MASK}?PROFILE=s3:text&accesskey={ACCESS_KEY}&secretkey={SECRET_KEY}&endpoint=storage.yandexcloud.net')
format 'CSV' (delimiter ',' header);


create readable external table pxf_pg_ignore(deviceid text)
LOCATION ('pxf://{DB schema.table ex. public.ignore}?PROFILE=JDBC&JDBC_DRIVER=org.postgresql.Driver&DB_URL=jdbc:postgresql://{Cluster URL}:6432/{DB NAME}&USER={USER}&PASS={PASSWORD}')
FORMAT 'CUSTOM' (FORMATTER='pxfwritable_import');


create writable external table pxf_s3_sensors_out(
	deviceid text, 
	seconds_counter int, 
	message_id int, 
	accel_pedal_position int, 
	altitude float, 
	battery_voltage float, 
	brake_pedal_position int, 
	cabin_temperature smallint,
	course smallint, 
	engine_oil_life smallint,
	engine_speed smallint,
	fuel_level int, 
	gear_lever_position int, 
	heading smallint,
	latitude float,
	longitude float,
	odometer int,
	power_pack_status smallint,
	satqty smallint,
	speed smallint,
	tcu_common_datetime timestamp,
	total_operation_hours int)
LOCATION('pxf://{S3_BUCKET}/{FILE_NAME_MASK}?PROFILE=s3:text&accesskey={ACCESS_KEY}&secretkey={SECRET_KEY}&endpoint=storage.yandexcloud.net')
format 'CSV';
