import uuid
import datetime
from airflow import DAG, settings
from airflow.models import Connection, Variable
from airflow.utils.trigger_rule import TriggerRule
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor
from airflow.providers.amazon.aws.operators.s3 import S3DeleteObjectsOperator
from airflow.providers.yandex.operators.yandexcloud_dataproc import (
    DataprocCreateClusterOperator,
    DataprocCreatePysparkJobOperator,
    DataprocDeleteClusterOperator,

)

# Common settings for your environment
YC_DP_FOLDER_ID = 'b1g8h1dr5cdi3fj80eop'  # YC catalog to create cluster
YC_DP_SUBNET_ID = 'e9bb04c0j4qp20ln18j1'  # YC subnet to create cluster
YC_DP_SA_ID = 'ajegn8jb49t8tmdap7ke'      # YC service account for Data Proc cluster
YC_DP_AZ = 'ru-central1-a'                # YC availability zone for Data Proc cluster

# Settings for S3 buckets
YC_INPUT_DATA_BUCKET = 'airflow-demo-input'  # YC S3 bucket for input data
YC_INPUT_FILES_PREFIX = 'sensors-data-part'  # Input CSV files prefix
YC_SOURCE_BUCKET = 'airflow-demo-source'     # YC S3 bucket for pyspark source files
YC_DP_LOGS_BUCKET = 'airflow-demo-logs'      # YC S3 bucket for Data Proc cluster logs

# Special Data Proc settings
YC_DP_METASTORE_URI = 'rc1a-dataproc-m-784a5wcybgs11baj.mdb.yandexcloud.net'  # Hive metastore DP cluster (master URI)
YC_DP_METASTORE_S3 = 'dataproc-1535/metastore/'                               # Hive metastore S3 bucket for blobs

session = settings.Session()
ycS3_connection = Connection(
    conn_id='yc-s3',
    conn_type='s3',
    host='https://storage.yandexcloud.net/',
    extra={
        "aws_access_key_id": Variable.get("S3_KEY_ID"),
        "aws_secret_access_key": Variable.get("S3_SECRET_KEY"),
        "host": "https://storage.yandexcloud.net/"
    }
)
if not session.query(Connection).filter(Connection.conn_id == ycS3_connection.conn_id).first():
    session.add(ycS3_connection)
    session.commit()

ycSA_connection = Connection(
    conn_id='yc-airflow-sa',
    conn_type='yandexcloud',
    extra={
        "extra__yandexcloud__public_ssh_key": Variable.get("DP_PUBLIC_SSH_KEY"),
        "extra__yandexcloud__service_account_json_path": Variable.get("DP_SA_AUTH_JSON_PATH")
    }
)
if not session.query(Connection).filter(Connection.conn_id == ycSA_connection.conn_id).first():
    session.add(ycSA_connection)
    session.commit()

with DAG(
        'DATA_INGEST',
        schedule_interval='@hourly',
        tags=['airflow-demo'],
        start_date=datetime.datetime.now(),
        max_active_runs=1,
        catchup=False
) as ingest_dag:

    s3_sensor = S3KeySensor(
        task_id='s3-sensor-task',
        bucket_key=f'{YC_INPUT_FILES_PREFIX}*.csv',
        bucket_name=YC_INPUT_DATA_BUCKET,
        wildcard_match=True,
        aws_conn_id=ycS3_connection.conn_id,
        poke_interval=10,
        dag=ingest_dag
    )

    create_spark_cluster = DataprocCreateClusterOperator(
        task_id='dp-cluster-create-task',
        folder_id=YC_DP_FOLDER_ID,
        cluster_name=f'tmp-dp-{uuid.uuid4()}',
        cluster_description='Temporary cluster for Spark processing under Airflow orchestration',
        subnet_id=YC_DP_SUBNET_ID,
        s3_bucket=YC_DP_LOGS_BUCKET,
        service_account_id=YC_DP_SA_ID,
        zone=YC_DP_AZ,
        cluster_image_version='2.0.43',
        enable_ui_proxy=False,
        masternode_resource_preset='s2.small',
        masternode_disk_type='network-ssd',
        masternode_disk_size=200,
        computenode_resource_preset='m2.large',
        computenode_disk_type='network-ssd',
        computenode_disk_size=200,
        computenode_count=2,
        computenode_max_hosts_count=5,
        services=['YARN', 'SPARK'],  # Creating lightweight Spark cluster
        datanode_count=0,            # With no data nodes
        properties={                 # But pointing it to remote Metastore cluster
            'spark:spark.hive.metastore.uris': f'thrift://{YC_DP_METASTORE_URI}:9083',
            'spark:spark.hive.metastore.warehouse.dir': f's3a://{YC_DP_METASTORE_S3}',
        },
        connection_id=ycSA_connection.conn_id,
        dag=ingest_dag
    )

    poke_spark_processing = DataprocCreatePysparkJobOperator(
        task_id='dp-cluster-pyspark-task',
        main_python_file_uri=f's3a://{YC_SOURCE_BUCKET}/DataProcessing.py',
        connection_id=ycSA_connection.conn_id,
        dag=ingest_dag
    )

    clean_input_buket = S3DeleteObjectsOperator(
        task_id='clean_input_buket',
        prefix=YC_INPUT_FILES_PREFIX,
        bucket=YC_INPUT_DATA_BUCKET,
        aws_conn_id=ycS3_connection.conn_id,
        dag=ingest_dag
    )

    delete_spark_cluster = DataprocDeleteClusterOperator(
        task_id='dp-cluster-delete-task',
        trigger_rule=TriggerRule.ALL_DONE,
        dag=ingest_dag
    )

    s3_sensor >> create_spark_cluster >> poke_spark_processing >> clean_input_buket >> delete_spark_cluster
