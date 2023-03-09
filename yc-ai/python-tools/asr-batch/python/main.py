from botocore.exceptions import ClientError
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
    's3_prefix_log'   : os.environ['S3_PREFIX_LOG'],
    's3_bucket_output': os.environ['S3_BUCKET'],
    's3_prefix_output': os.environ['S3_PREFIX_OUT'],
    's3_key'          : os.environ['S3_KEY'],
    's3_secret'       : os.environ['S3_SECRET'],
    'api_key_id'      : os.environ['API_KEY'],
    'api_key_secret'  : os.environ['API_SECRET']
}

suffixes = (".mp3", ".wav", ".ogg")

url_operations_api = "https://operation.api.cloud.yandex.net/operations/"
url_transcribe_api = "https://transcribe.api.cloud.yandex.net/speech/stt/v2/longRunningRecognize"
request_header = {'Authorization': 'Api-Key {}'.format(config['api_key_secret'])}

# State - Setting up S3 client
s3 = boto3.client('s3',
    endpoint_url            = 'https://storage.yandexcloud.net',
    aws_access_key_id       = config['s3_key'],
    aws_secret_access_key   = config['s3_secret'] 
)

# Function - Get SpeechKit specific configuration
def get_speechkit_config():
    default = {
        'lang': 'ru-RU'
    }
    key = config['s3_prefix']+'/config.json'
    try:
        response = s3.get_object(Bucket=config['s3_bucket'], Key=key)
        logging.info("Config was read: {}".format(key))
    except ClientError as e:
        logging.warning("Config read failed, using default: {}".format(e))
        return default
    
    file_content = response['Body'].read().decode('utf-8')
    json_content = json.loads(file_content)

    return json_content

speechkit = get_speechkit_config()

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

# Function - Create recognition task
def create_recognition_task(url, file_type, lang = speechkit['lang']):
    if (file_type == "mp3"):
        request_body = {
            "config": {
                "specification": {
                    "audioEncoding": "MP3",
                    "languageCode": lang
                }
            },
            "audio": {
                "uri": url
            }
        }
    elif (file_type == "wav"):
        request_body = {
            "config": {
                "specification": {
                    "audioEncoding": "LINEAR16_PCM",
                    "sampleRateHertz": "48000",
                    "languageCode": lang
                }
            },
            "audio": {
                "uri": url
            }
        }
    elif (file_type == "ogg"):
        request_body = {
            "config": {
                "specification": {
                    "audioEncoding": "OGG_OPUS",
                    "languageCode": lang
                }
            },
            "audio": {
                "uri": url
            }
        }
    
    try:
        response = requests.post(url_transcribe_api, headers=request_header, json=request_body)
        response.raise_for_status()
    except requests.exceptions.HTTPError as e:
        logging.error("Transcribe request failed: {}".format(e))
    except requests.exceptions.RequestException as e:
        logging.error("Transcribe request failed: {}".format(e))
    else:
        request_data = response.json()
    
        if(request_data['id']):
            logging.info("Operation {}".format(request_data['id']))
            logging.info("Operation has been created for {}".format(url))
            return request_data
        else: 
            logging.error("Operation ID is missing in the response")
            return {"Status": "None"}

# Function - Check recognition task results
def check_operation():
    return None

def write_process_status(key, data):
    json_data = json.dumps(data)
    try:
        s3.put_object(Bucket=config['s3_bucket'], Key=key, Body=json_data)
        logging.info("Object process status was written: {}".format(key))
        return True
    except ClientError as e:
        logging.error("Object upload failed: {}".format(e))
        return None

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

        key_process = config['s3_prefix_log'] + key[len(config['s3_prefix']):] + ".json"

        try:
            s3.head_object(Bucket=config['s3_bucket'], Key=key_process)
        except Exception as e:
            logging.info("Object doesn't exist {}".format(e))
        else:
            logging.info("Skipping object: {}".format(key))
            continue

        if (key.lower().endswith(".mp3")):
           file_type = "mp3"
        elif (key.lower().endswith(".ogg")):
            file_type = "ogg"
        elif (key.lower().endswith(".wav")):
            file_type = "wav"

        url = create_presigned_url(key)
        result = create_recognition_task(url, file_type)

        if not (result == None):
            write_process_status(key_process, result)

# Core - Check object in process
def check_processing_objects():
    try:
        object_list = s3.list_objects_v2(Bucket=config['s3_bucket'], Prefix=config['s3_prefix_log'])
        logging.info("Bucket listing successful")
        objects = object_list.get('Contents')

        if not (object_list.get('KeyCount') == 0):
            logging.info("Bucket listing successful")
            objects = object_list.get('Contents')
        else:
            logging.info("Processing directory is empty")
            return None

    except ClientError as e:
        logging.error("Bucket listing failed: {}".format(e))
        return None
    
    for obj in objects:
        key = obj.get('Key')

        if not (key.endswith(".json")):
            continue

        try:
            response = s3.get_object(Bucket=config['s3_bucket'], Key=key)
            logging.info("Object was read: {}".format(key))
        except ClientError as e:
            logging.error("Object read failed: {}".format(e))
            continue
        
        file_content = response['Body'].read().decode('utf-8')
        json_content = json.loads(file_content)

        if not (json_content['id']):
            logging.info("No operation ID in file: {}".format(key))
            continue

        if (json_content['done']):
            logging.info("Already processed: {}".format(json_content['id']))
            continue

        try:
            result = requests.get(url_operations_api+json_content['id'], headers=request_header)
            result.raise_for_status()
        except requests.exceptions.HTTPError as e:
            logging.error("Operation status check failed: {}".format(e))
            continue
        except requests.exceptions.RequestException as e:
            logging.error("Operation status check failed: {}".format(e))
            continue
        else:
            result_data = result.json()

        if not (result_data['done']):
            logging.info("Operation in progress: {}".format(result_data['id']))
            continue
        
        result_key = config['s3_prefix_output'] + key[len(config['s3_prefix_log']):]
        result_body = str(json.dumps(result_data, ensure_ascii=False, indent=2))

        try:
            s3.put_object(Bucket=config['s3_bucket'], Key=result_key, Body=result_body, ContentType="application/json")
            logging.info("Object process result was written: {}".format(result_key))
        except ClientError as e:
            logging.error("Object result upload failed: {}".format(e))
            continue

        body_complete = {
            "done": "true",
            "id": json_content['id']
        }

        try:
            s3.put_object(Bucket=config['s3_bucket'], Key=key, Body=json.dumps(body_complete))
            logging.info("Object process file updated: {}".format(key))
        except ClientError as e:
            logging.error("Object process update failed: {}".format(e))
            continue
        
# Main handler

process_input_objects()
check_processing_objects()