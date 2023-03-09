from botocore.exceptions import ClientError
import base64
import boto3
import json
import logging
import os
import requests

# Configuration - Logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

# Variables
config = {
    's3_bucket'       : os.environ['S3_BUCKET'],
    's3_prefix'       : os.environ['S3_PREFIX'],
    's3_bucket_output': os.environ['S3_BUCKET'],
    's3_prefix_output': os.environ['S3_PREFIX_OUT'],
    's3_key'          : os.environ['S3_KEY'],
    's3_secret'       : os.environ['S3_SECRET'],
    'api_key_secret'  : os.environ['API_SECRET'],
    'folder_id'       : os.environ['FOLDER_ID']
}

suffixes = (".jpg", ".jpeg", ".png", ".pdf")

url_vision_api = "https://vision.api.cloud.yandex.net/vision/v1/batchAnalyze"
request_header = {
    'Authorization': 'Api-Key {}'.format(config['api_key_secret']),
    'Content-Type': 'application/json'
}

# State - Setting up S3 client
s3 = boto3.client('s3',
    endpoint_url            = 'https://storage.yandexcloud.net',
    aws_access_key_id       = config['s3_key'],
    aws_secret_access_key   = config['s3_secret'] 
)

# Function - Create presigned URL for an object
def create_presigned_url(object, expiration = 3600):
    try:
        response = s3.generate_presigned_url('get_object',
            Params={
                'Bucket': config['s3_bucket'],
                'Key': object
            },
            ExpiresIn = expiration
        )
    except ClientError as e:
        logging.error("Generate presigned URL failed: {}".format(e))
        return None
    return response

# Function - Extract json
def json_extract(obj, key):
    arr = []

    def extract(obj, arr, key):
        if isinstance(obj, dict):
            for k, v in obj.items():
                if isinstance(v, (dict, list)):
                    extract(v, arr, key)
                elif k == key:
                    arr.append(v)
        elif isinstance(obj, list):
            for item in obj:
                extract(item, arr, key)
        return arr

    values = extract(obj, arr, key)
    return values

# Function - Analyze image
def analyze_image(url):
    # download image
    file = requests.get(url)
    # convert to binary
    content = base64.b64encode(file.content)
    content_str = str(content)[2:-1]
    # construct json
    request_body = {
        "folderId": config['folder_id'],
        "analyze_specs": {
            "content": content_str,
            "features": {
                "type": "TEXT_DETECTION",
                "text_detection_config": {
                    "language_codes": ["en","ru"]
                }
            }
        }
    }
    # send request
    try:
        response = requests.post(url_vision_api, headers=request_header, json=request_body)
        response.raise_for_status()
    except requests.exceptions.HTTPError as e:
        logging.error("Transcribe request failed: {}".format(e))
    except requests.exceptions.RequestException as e:
        logging.error("Transcribe request failed: {}".format(e))
    else:
        response_data = response.json()
    # save response
    return response_data

# Function - Analyze image
def analyze_pdf(url):
    # download image
    file = requests.get(url)
    # convert to binary
    content = base64.b64encode(file.content)
    content_str = str(content)[2:-1]
    # construct json
    request_body = {
        "folderId": config['folder_id'],
        "analyze_specs": {
            "content": content_str,
            "mime_type": "application/pdf",
            "features": {
                "type": "TEXT_DETECTION",
                "text_detection_config": {
                    "language_codes": ["en","ru"]
                }
            }
        }
    }
    # send request
    try:
        response = requests.post(url_vision_api, headers=request_header, json=request_body)
        response.raise_for_status()
    except requests.exceptions.HTTPError as e:
        logging.error("Transcribe request failed: {}".format(e))
    except requests.exceptions.RequestException as e:
        logging.error("Transcribe request failed: {}".format(e))
    else:
        response_data = response.json()
    # save response
    return response_data

# Core - Process input directory
def process_input_objects():
    try:
        result = s3.list_objects_v2(Bucket=config['s3_bucket'], Prefix=config['s3_prefix'])

        if not (result.get('KeyCount') == 0):
            logging.info("Bucket listing successful")
            objects = result.get('Contents')
        else:
            logging.info("Input directory is empty")
            return None

    except ClientError as e:
        logging.error("Bucket listing failed: {}".format(e))
        return None
    
    for obj in objects:
        key = obj.get('Key')

        if not (key.lower().endswith(suffixes)):
            logging.info("Not supported file format: {}".format(key))
            continue

        key_process = config['s3_prefix_output'] + key[len(config['s3_prefix']):] + ".json"

        try:
            s3.head_object(Bucket=config['s3_bucket_output'], Key=key_process)
        except Exception as e:
            logging.info("Object doesn't exist {}".format(e))
        else:
            logging.info("Already processed, skipping object: {}".format(key))
            continue
        
        url = create_presigned_url(key)
        
        if(key.lower().endswith(".pdf")):
            result = analyze_pdf(url)
        else:
            result = analyze_image(url)

        result_key = config['s3_prefix_output'] + key[len(config['s3_prefix']):] + '.json'
        result_json = json.dumps(result)

        try:
            s3.put_object(Bucket=config['s3_bucket_output'], Key=result_key, Body=result_json, ContentType="application/json")
            logging.info("Object process result was written: {}".format(result_key))
        except ClientError as e:
            logging.error("Object result upload failed: {}".format(e))
            continue
            
        
        result_key = config['s3_prefix_output'] + key[len(config['s3_prefix']):] + '.txt'
        words = json_extract(result, 'text')
        words_concat = " ".join(words)

        try:
            s3.put_object(Bucket=config['s3_bucket_output'], Key=result_key, Body=words_concat, ContentType="application/text")
            logging.info("Object process result was written: {}".format(result_key))
        except ClientError as e:
            logging.error("Object result upload failed: {}".format(e))
            continue

process_input_objects()