from pyspark.sql import SparkSession

# Settings for S3 buckets
YC_INPUT_DATA_BUCKET = 'airflow-demo-input'
YC_INPUT_DATA_FILES_MASK = 'sensors-data-part*.csv'
YC_OUTPUT_DATA_BUCKET = 'airflow-demo-output'


# Pay attention to enableHiveSupport() call
spark = SparkSession.builder.enableHiveSupport().getOrCreate()

data = spark.read.format('csv') \
    .option('header', True) \
    .option("delimiter", ",") \
    .load(f's3a://{YC_INPUT_DATA_BUCKET}/{YC_INPUT_DATA_FILES_MASK}')

ignore = spark.sql(sqlQuery="select deviceid from ignore")

data.join(ignore, on='deviceid', how='left_anti') \
    .repartition(1) \
    .write.format('parquet') \
    .save(f's3a://{YC_OUTPUT_DATA_BUCKET}/sensors')


# Just an example of Postgres connection with SSL protection
#ds = spark.read.format("jdbc") \
#    .option("driver", "org.postgresql.Driver") \
#    .option("url", f"jdbc:postgresql://{JDBC_HOSTNAME}:{JDBC_PORT}/{JDBC_DATABASE}") \
#    .option("ssl", "True") \
#    .option("sslrootcert", "/usr/local/share/ca-certificates/yandex-cloud-ca.crt") \
#    .option("dbtable", "ds") \
#    .option("user", "") \
#    .option("password", "") \
#    .load()