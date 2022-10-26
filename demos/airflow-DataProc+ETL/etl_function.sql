create or replace function poke_etl()
returns void as $$
begin 
	insert into pxf_s3_sensors_out
	select 
		deviceid, 
		seconds_counter, 
		message_id, 
		accel_pedal_position, 
		altitude, 
		battery_voltage, 
		brake_pedal_position, 
		cabin_temperature,
		course, 
		engine_oil_life,
		engine_speed,
		fuel_level, 
		gear_lever_position, 
		heading,
		latitude,
		longitude,
		odometer,
		power_pack_status,
		satqty,
		speed,
		tcu_common_datetime,
		total_operation_hours
	from pxf_s3_sensors
	where deviceid not in (select distinct deviceid from pxf_pg_ignore);
end;
$$ language plpgsql