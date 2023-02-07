
import yaml
import boto3
import time
import requests
import os
import json

sqs_client = boto3.client(
        service_name='sqs',
        endpoint_url='https://message-queue.api.cloud.yandex.net',
        region_name='ru-central1'
    )

def get_config(bucket,path,endpoint_url='https://storage.yandexcloud.net'):
    '''
    gets config in special format from bucket
    :param bucket: bucket name
    :param path: path of the config yaml file
    :param endpoint_url: url of object storeages
    :return: config dict
    '''

    session = boto3.session.Session()
    s3_client = session.client(
        service_name='s3',
        endpoint_url=endpoint_url
    )

    response = s3_client.get_object(Bucket=bucket, Key=path)
    config = yaml.load(response["Body"], Loader=yaml.FullLoader)
    return config

def check_router_statuses(config,iam_token):
    '''
    checks router statuses and fails over if there is a problem. updates config in the end
    :param config: config dict
    :param iam_token: token for auth
    :return: updated config
    '''
    r = requests.get("https://load-balancer.api.cloud.yandex.net/load-balancer/v1/networkLoadBalancers/%s:getTargetStates?targetGroupId=%s" % (config['loadBalancerId'],config['targetGroupId']), headers={'Authorization': 'Bearer %s'  % iam_token})
    fullStatus = r.json()['targetStates']
    for real in fullStatus:
        config['routes_config'][real['address']]['status'] = real['status']
    first_router_status = config['routes_config'][list(config['routes_config'].keys())[0]]['status']
    for destination, value in config['routes_config'].items():
        if first_router_status != 'HEALTHY' and value['active'] == 'primary':
            '''
            IF PRIMARY ROUTER IS NOT HEALTHY SWITCHES ALL SUBNETS TO SECONDARY ROUTER
            '''
            subnet_list_to_change = value['subnets']
            route_table_to_change = value['route_table']['secondary']
            config['routes_config'][destination]['active'] = 'secondary'
            print('PRIMARY ROUTER %s is NOT HEALTHY, FAILING OVER to SECONDARY ROUTER %s for SUBNETS %s' % (list(config['routes_config'].keys())[0], list(config['routes_config'].keys())[1], value['subnets']))
            failover(route_table_to_change, subnet_list_to_change, iam_token)
        elif first_router_status == 'HEALTHY' and value['active'] == 'secondary':
            '''
            IF PRIMARY ROUTER IS HEALTHY AND I AM CURRENTLY USING SECONDARY ROUTER SWITCHES ALL SUBNETS BACK TO PRIMARY ROUTER
            '''
            subnet_list_to_change = value['subnets']
            route_table_to_change = value['route_table']['primary']
            config['routes_config'][destination]['active'] = 'primary'
            print('PRIMARY ROUTER %s is HEALTHY, FALLING BACK to PRIMARY ROUTER for SUBNETS %s' % (list(config['routes_config'].keys())[0], value['subnets']))
            failover(route_table_to_change, subnet_list_to_change, iam_token)
        else:
            print('%s ROUTER is USED for SUBNETS %s' % (value['active'].upper(), value['subnets']))

    return config

def failover(route_table_id,subnet_list,iam_token):
    '''
    changes route table of subnet list
    :param route_tableID: id of the route table
    :param iam_token: token for auth
    :param subnet_list:  subnet list where route table is changed
    :return:
    '''
    queue_url = os.environ.get('YMQ_URL')

    for subnet_id in subnet_list:
        data = {
            'subnet_id': subnet_id,
            'route_table_id': route_table_id
         }
        sqs_client.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(data),
        )
        print('Send a request to change subnet %s route table to  %s' % (subnet_id,route_table_id))


def put_config(bucket,path,config,endpoint_url='https://storage.yandexcloud.net'):
    '''
    uploads config file to the bucket
    :param bucket: bucket name
    :param path: config path in the bucket
    :param local_config: local path of config
    :param config: configdict
    :param endpoint_url: url of the config
    :return:
    '''
    session = boto3.session.Session()
    s3_client = session.client(
        service_name='s3',
        endpoint_url=endpoint_url
    )

    with open('/tmp/config.yaml', 'w') as outfile:
        yaml.dump(config, outfile, default_flow_style=False)

    s3_client.upload_file('/tmp/config.yaml', bucket, path)

def handler(event, context):
   
    bucket = os.getenv('BUCKET_NAME')
    path = os.getenv('CONFIG_PATH')
    iam_token = context.token['access_token']
    config = get_config(bucket, path)
    config = check_router_statuses(config, iam_token)
    put_config(bucket, path , config)

