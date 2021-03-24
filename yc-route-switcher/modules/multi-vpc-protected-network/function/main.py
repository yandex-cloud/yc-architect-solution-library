
import yaml
import boto3
import time
import requests
import os



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

def check_router_statuses(config,iamToken):
    '''
    checks router statuses and fails over if there is a problem. updates config in the end
    :param config: config dict
    :param iamToken: token for auth
    :return: updated config
    '''
    r = requests.get("https://load-balancer.api.cloud.yandex.net/load-balancer/v1/networkLoadBalancers/%s:getTargetStates?targetGroupId=%s" % (config['loadBalancerId'],config['targetGroupId']), headers={'Authorization': 'Bearer %s'  % iamToken})
    print(r)
    fullStatus = r.json()['targetStates']
    for real in fullStatus:
        config['routes_config'][real['address']]['status'] = real['status']
    for destination, value in config['routes_config'].items():
        if value['status'] != 'HEALTHY' and value['active'] == 'primary':
            '''
            IF MY PRIMARY ROUTE IS NOT HEALTHY IM FAILING OVER TO SECONDARY
            '''
            subnet_list_to_change = value['subnets']
            route_table_to_change = value['route_table']['secondary']
            config['routes_config'][destination]['active'] = 'secondary'
            print('MY PRIMARY ROUTE to %s IS NOT HEALTHY IM FAILING OVER TO SECONDARY' % destination)
            failover(route_table_to_change, subnet_list_to_change,iamToken)
        elif value['status'] == 'HEALTHY' and value['active'] == 'secondary':
            '''
            IF MY PRIMARY ROUTE IS HEALTHY AND IM CURRENTLY USING SECONDARY IM FAILING BACK TO PRIMARY
            '''
            subnet_list_to_change = value['subnets']
            route_table_to_change = value['route_table']['primary']
            config['routes_config'][destination]['active'] = 'primary'
            print('MY PRIMARY ROUTE to %s IS HEALTHY AND IM CURRENTLY USING SECONDARY IM FAILING BACK TO PRIMARY' % destination)
            failover(route_table_to_change, subnet_list_to_change, iamToken)
        else:
            print('ROUTE TO %s is FINE' % destination)

    return config

def failover(route_tableID,subnet_list,iamToken):
    '''
    changes route table of subnet list
    :param route_tableID: id of the route table
    :param iamToken: token for auth
    :param subnet_list:  subnet list where route table is changed
    :return:
    '''
    print('failing over route table %s for subnets %s' % (route_tableID,' '.join(subnet_list)))
    for subnetID in subnet_list:
        r = requests.patch('https://vpc.api.cloud.yandex.net/vpc/v1/subnets/%s' % subnetID, json={"updateMask": "routeTableId", "routeTableId": "" } ,headers={'Authorization': 'Bearer %s'  % iamToken})
        operationID = r.json()['id']
        check_operation(operationID,iamToken)
        r = requests.patch('https://vpc.api.cloud.yandex.net/vpc/v1/subnets/%s' % subnetID, json={"updateMask": "routeTableId", "routeTableId": route_tableID } ,headers={'Authorization': 'Bearer %s'  % iamToken})
        operationID = r.json()['id']
        check_operation(operationID,iamToken)

def check_operation(operationID,iamToken):
    '''
    waits for operation to complete
    :param operationID: id of the operation
    :param iamToken: token for auth
    :return: nothing - just stops when operation completes
    '''
    for n in range(30):
        r = requests.get('https://operation.api.cloud.yandex.net/operations/%s' % operationID, headers={'Authorization': 'Bearer %s' % iamToken})
        operationStatus = r.json()['done']
        if operationStatus == True:
            print('Operation %s is done' % operationID)
            break
        time.sleep(1)

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
    iamToken = context.token['access_token']
    config = get_config(bucket, path)
    config = check_router_statuses(config, iamToken)
    put_config(bucket, path , config)

