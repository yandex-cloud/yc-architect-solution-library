from google.cloud import bigquery
import sys
import argparse
import time
import subprocess


def parse_args():
    parser = argparse.ArgumentParser(description='Export data from Google Big Query to Yandex Cloud object storage')
    parser.add_argument('--bq_project', type=str, help='GBQ project ID')
    parser.add_argument('--bq_location', type=str, help='GBQ table AND GS location')
    parser.add_argument('--gs_bucket', type=str, help='GS export destination bucket')
    parser.add_argument('--yc_bucket', type=str, help='YC copy destination bucket')
    parser.add_argument('--gsutil_path', type=str, help='GSutil exec path', default='gsutil')
    return parser.parse_args()


def select_from_list(message, elements):
    print(message)
    print("\t{}. {}".format(0, "Export all"))
    for ind in range(len(elements)):
        if isinstance(elements[ind].reference, bigquery.DatasetReference):
            print("\t{}. {}".format(ind+1, elements[ind].reference.dataset_id))
        elif isinstance(elements[ind].reference, bigquery.TableReference):
            print("\t{}. {}".format(ind+1, elements[ind].reference.table_id))
    try:
        return int(input("(any letter for cancel) >> "))
    except ValueError:
        print("Exiting")
        sys.exit()


if __name__ == '__main__':
    args = parse_args()
    client = bigquery.Client()

    datasets = list(client.list_datasets(args.bq_project))
    dataset_selector = select_from_list("Datasets in project {}".format(args.bq_project), datasets)
    export_list = []
    for i in range(len(datasets)):
        dataset_ref = datasets[i].reference
        if dataset_selector == 0:
            export_list += list(client.list_tables(dataset_ref))
        else:
            if i == dataset_selector - 1:
                tables = list(client.list_tables(dataset_ref))
                table_selector = select_from_list("Tables in dataset {}".format(dataset_ref.dataset_id),
                                                  tables)
                for j in range(len(tables)):
                    if table_selector == 0 or j == table_selector - 1:
                        export_list.append(tables[j])

    print("Starting tables export")
    for n in range(len(export_list)):
        table_ref = export_list[n].reference

        # Creating Extract Job config. Selecting compression level and data format.
        job_config = bigquery.job.ExtractJobConfig()
        job_config.compression = bigquery.Compression.GZIP
        job_config.destination_format = bigquery.DestinationFormat.PARQUET

        print("Exporting {} table".format(table_ref.table_id))
        extract_job = client.extract_table(
            source=table_ref,
            destination_uris="gs://{}/{}".format(args.gs_bucket, "{}-*".format(table_ref.table_id)),
            job_id="export-job-{}-{}".format(table_ref.table_id, round(time.time() * 1000)),
            location=args.bq_location,
            job_config=job_config)
        extract_job.result()
    print("Tables export done")

    # Calling gsutil rsync to synchronize source and destination buckets.
    source_uri = "gs://{}/".format(args.gs_bucket)
    destination_uri = "s3://{}/".format(args.yc_bucket)
    print("Synchronizing {} with {}...".format(source_uri, destination_uri))
    proc = subprocess.Popen([args.gsutil_path, "-m", "rsync", source_uri, destination_uri],
                            stdout=sys.stdout,
                            stderr=sys.stderr)
    proc.communicate()
    print("Buckets synchronization done")
