import datetime
import psycopg2
from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator
from airflow_clickhouse_plugin.operators.clickhouse_operator import ClickHouseOperator
from airflow.providers.amazon.aws.operators.s3 import S3DeleteObjectsOperator


# Settings for Greenplum and Clickhouse clusters
GP_CLUSTER_ID = "c9q7tp54r11rn8nihlfr"  # Greenplum cluster for ETL
CH_CLUSTER_ID = "c9qck2igsl63j10oellk"  # Clickhouse cluster for datamarts


def greenplum_call():
    conn = psycopg2.connect(f"""
        host=c-{GP_CLUSTER_ID}.rw.mdb.yandexcloud.net
        port=5432
        sslmode=verify-full
        dbname=postgres
        user={Variable.get("DEMO_USER")}
        password={Variable.get("DEMO_PWD")}
        target_session_attrs=read-write
    """)
    q = conn.cursor()
    q.execute('SELECT poke_etl();')
    conn.close()


with DAG(
        'ETL_ORCHESTRATION',
        schedule_interval="@daily",
        tags=['airflow-demo'],
        start_date=datetime.datetime.now(),
        catchup=False,
        max_active_runs=1
) as ingest_dag:
    poke_greenplum_processing = PythonOperator(
        task_id='process-greenplum-call-task',
        python_callable=greenplum_call,
        dag=ingest_dag
    )

    poke_clickhouse_processing = ClickHouseOperator(
        task_id='process-clickhouse-call-task',
        database='sensors',
        sql=f'''
                INSERT INTO sensors.sensors
                SELECT
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
                FROM s3Cluster({CH_CLUSTER_ID}, 'https://storage.yandexcloud.net/airflow-demo-output/gp/*', 
                        {Variable.get("DEMO_KEY")}, {Variable.get("DEMO_SECRET")},  
                        'CSV', 'deviceid String, seconds_counter Int32, message_id Int32, accel_pedal_position Int32, 
                        altitude Float, battery_voltage Float, brake_pedal_position Int32, cabin_temperature Int32,
                        course Int32, engine_oil_life Int32, engine_speed Int32, fuel_level Int32, 
                        gear_lever_position Int32, heading Int32, latitude Float, longitude Float, odometer Int32,
                        power_pack_status Int32, satqty Int32, speed Int32, tcu_common_datetime Timestamp,
                        total_operation_hours Int32')
            ''',
        clickhouse_conn_id='yc_clickhouse'
    )

    clean_input_bucket = S3DeleteObjectsOperator(
        task_id='clean_input_buket',
        prefix='sensors-data-part-0000',
        bucket='airflow-demo-input',
        aws_conn_id='yc-s3',
        dag=ingest_dag
    )

    clean_staging_bucket = S3DeleteObjectsOperator(
        task_id='clean_staging_bucket',
        prefix='gp/',
        bucket='airflow-demo-output',
        aws_conn_id='yc-s3',
        dag=ingest_dag
    )

    poke_greenplum_processing >> poke_clickhouse_processing >> clean_input_bucket >> clean_staging_bucket
