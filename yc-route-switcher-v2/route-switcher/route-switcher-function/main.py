import yaml
import os
import boto3
import requests
import concurrent.futures as pool
import sys

iam_token = ""
path = os.getenv('CONFIG_PATH')
bucket = os.getenv('BUCKET_NAME')
cron_interval = os.getenv('CRON_INTERVAL')
back_to_primary = os.getenv('BACK_TO_PRIMARY').lower()

def get_config(endpoint_url='https://storage.yandexcloud.net'):
    '''
    gets config in special format from bucket
    :param endpoint_url: url of object storage
    :return: configuration dictionary with route tables and load balancer id
    '''

    session = boto3.session.Session()
    s3_client = session.client(
        service_name='s3',
        endpoint_url=endpoint_url
    )

    response = s3_client.get_object(Bucket=bucket, Key=path)
    config = yaml.load(response["Body"], Loader=yaml.FullLoader)
    return config

def check_router_statuses(config):
    '''
    checks routers status and fails over if router failed
    :param config: configuration dictionary with route tables and load balancer id
    '''

    # get router status from NLB
    try:    
        r = requests.get("https://load-balancer.api.cloud.yandex.net/load-balancer/v1/networkLoadBalancers/%s:getTargetStates?targetGroupId=%s" % (config['loadBalancerId'], config['targetGroupId']), headers={'Authorization': 'Bearer %s'  % iam_token})
    except Exception as e:
        print(f"Request to get target states in load balancer {config['loadBalancerId']} failed due to: {e}. Retrying in {cron_interval} seconds...")
        return
    
    if r.status_code != 200:
        print(f"Unexpected status code {r.status_code} for getting target states in load balancer {config['loadBalancerId']}. More details: {r.json().get('message')}. Retrying in {cron_interval} seconds...")
        return

    if 'targetStates' in r.json():
        if len(r.json()['targetStates']) < 2:
            # check whether we have at least two routers configured, if not return and generate an error
            print(f"At least two routers should be in load balancer {config['loadBalancerId']}. Please add one more router. Retrying in {cron_interval} seconds...")
            return
        else:
            # prepare targetStatus dictionary with {key:value}, where key - healthchecked IP address of router, value - HEALTHY or other state
            targetStatus = {}
            for target in r.json()['targetStates']:
                targetStatus[target['address']] = target['status']
                print(f"Router {target['address']} is {target['status']}.")
            if 'HEALTHY' not in targetStatus.values():
                # all routers are not healthy, exit from function 
                print(f"All routers are not healthy. Can not switch next hops for route tables. Retrying in {cron_interval} seconds...")
                return
            if 'routers' in config:
                if config['routers'] is None:
                    # check whether we have routers in config
                    print(f"Routers configuration does not exist. Please add 'routers' input variable for Terraform route-switcher module. Retrying in {cron_interval} seconds...")
                    return
            else:
                print(f"Routers configuration does not exist. Please add 'routers' input variable for Terraform route-switcher module. Retrying in {cron_interval} seconds...")
                return
            healthy_nexthops = {}
            unhealthy_nexthops = {}
            for router in config['routers']:
                if 'healthchecked_ip' in router and router['healthchecked_ip']:
                    router_hc_address = router['healthchecked_ip']
                else:
                    print(f"Router does not have 'healthchecked_ip' configuration. Please add 'healthchecked_ip' value in 'routers' input variable for Terraform route-switcher module. Retrying in {cron_interval} seconds...")
                    continue
                if router_hc_address in targetStatus:
                    if 'interfaces' in router and router['interfaces']:
                        router_interfaces = router['interfaces']
                    else:
                        print(f"Router does not have 'interfaces' configuration. Please add 'interfaces' list in 'routers' input variable for Terraform route-switcher module. Retrying in {cron_interval} seconds...")
                        continue
                    if targetStatus[router_hc_address] != 'HEALTHY':
                        # prepare dictionary with UNHEALTHY nexthops as {key:value}, where key - nexthop address, value - nexthop address of backup router
                        for interface in router_interfaces:
                            if 'own_ip' in interface and interface['own_ip']:
                                if 'backup_peer_ip' in interface and interface['backup_peer_ip']:
                                    unhealthy_nexthops[interface['own_ip']] = interface['backup_peer_ip']
                                else:
                                    print(f"Router interface does not have 'backup_peer_ip' configuration. Please add 'backup_peer_ip' value in 'routers' input variable for Terraform route-switcher module. Retrying in {cron_interval} seconds...")
                                    continue
                            else:
                                print(f"Router interface does not have 'own_ip' configuration. Please add 'own_ip' value in 'routers' input variable for Terraform route-switcher module. Retrying in {cron_interval} seconds...")
                                continue  
                    else:
                        # prepare dictionary with HEALTHY nexthops as {key:value}, where key - nexthop address, value - nexthop address of backup router
                        for interface in router_interfaces:
                            if 'own_ip' in interface and interface['own_ip']:
                                if 'backup_peer_ip' in interface and interface['backup_peer_ip']:
                                    healthy_nexthops[interface['own_ip']] = interface['backup_peer_ip']
                                else:
                                    print(f"Router interface does not have 'backup_peer_ip' configuration. Please add 'backup_peer_ip' value in 'routers' input variable for Terraform route-switcher module. Retrying in {cron_interval} seconds...")
                                    continue
                            else:
                                print(f"Router interface does not have 'own_ip' configuration. Please add 'own_ip' value in 'routers' input variable for Terraform route-switcher module. Retrying in {cron_interval} seconds...")
                                continue
                else:
                    print(f"Router {router_hc_address} is not in target endpoints of load balancer {config['loadBalancerId']}. Please check load balancer configuration or 'routers' input variable for Terraform route-switcher module. Retrying in {cron_interval} seconds...")

    else:
        print(f"There are no target endpoints in load balancer {config['loadBalancerId']}. Please add two endpoints. Retrying in {cron_interval} seconds...")
        return
    
    if 'route_tables' in config:
        if config['route_tables'] is None:
            # check whether we have at least one route table in config
            print(f"There are no route tables in config file in bucket. Please add at least one route table. Retrying in {cron_interval} seconds...")
            return
    else:
        print(f"There are no route tables in config file in bucket. Please add at least one route table. Retrying in {cron_interval} seconds...")
        return

    all_routeTables = list()
    config_changed = False
    for config_route_table in config['route_tables']:
        try:    
            r = requests.get("https://vpc.api.cloud.yandex.net/vpc/v1/routeTables/%s" % config_route_table['route_table_id'], headers={'Authorization': 'Bearer %s'  % iam_token})
        except Exception as e:
            print(f"Request to get route table {config_route_table['route_table_id']} failed due to: {e}. Retrying in {cron_interval} seconds...")
            continue
        
        if r.status_code != 200:
            print(f"Unexpected status code {r.status_code} for getting route table {config_route_table['route_table_id']}. More details: {r.json().get('message')}. Retrying in {cron_interval} seconds...")
            continue

        if 'staticRoutes' in r.json():
            routeTable = r.json()['staticRoutes']
            if not len(routeTable):
                # check whether we have at least one route configured
                print(f"There are no routes in route table {config_route_table['route_table_id']}. Please add at least one route.")
                continue

            routeTable_changes = {'modified':False}
            routeTable_prefixes = set()
            for ip_route in routeTable: 
                # checking if next hop is one of a router addresses
                if ip_route['nextHopAddress'] in healthy_nexthops or ip_route['nextHopAddress'] in unhealthy_nexthops:
                    # populate routeTable_prefixes set with route table prefixes
                    routeTable_prefixes.add(ip_route['destinationPrefix'])
                    if ip_route['nextHopAddress'] in unhealthy_nexthops:
                        # if primary router is not healthy change next hop address to backup router  
                        backup_router = unhealthy_nexthops[ip_route['nextHopAddress']]
                        # also check whether backup router address is in healthy next hops
                        if backup_router in healthy_nexthops:
                            ip_route.update({'nextHopAddress':backup_router})
                            routeTable_changes = {'modified':True, 'next_hop':backup_router}
                        else:
                            print(f"Backup next hop {backup_router} is not healthy. Can not switch next hop {ip_route['nextHopAddress']} for route {ip_route['destinationPrefix']} in route table {config_route_table['route_table_id']}. Retrying in {cron_interval} seconds...")
                    else:
                        if 'routes' in config_route_table:
                            if ip_route['destinationPrefix'] in config_route_table['routes']:
                                # if route-switcher module has 'back_to_primary' input variable set as 'true' we back to primary router after its recovery
                                if back_to_primary == 'true':
                                    # get primary router from config stored in bucket
                                    primary_router = config_route_table['routes'][ip_route['destinationPrefix']]
                                    if primary_router in healthy_nexthops and ip_route['nextHopAddress'] != primary_router: 
                                        # if primary router became healthy and backup router is still used as next hop, change next hop address to primary router
                                        ip_route.update({'nextHopAddress':primary_router})
                                        routeTable_changes = {'modified':True, 'next_hop':primary_router}
                            else:
                                # insert route in config file stored in bucket
                                config_route_table['routes'].update({ip_route['destinationPrefix']:ip_route['nextHopAddress']}) 
                                config_changed = True
                        else:
                            # insert route in config file stored in bucket
                            config_route_table['routes'] = {}
                            config_route_table['routes'].update({ip_route['destinationPrefix']:ip_route['nextHopAddress']}) 
                            config_changed = True
            
            if routeTable_changes['modified']:
                # if next hop for some routes was changed add this table to all_routeTables list
                all_routeTables.append({'route_table_id':config_route_table['route_table_id'], 'next_hop':routeTable_changes['next_hop'], 'routes':sorted(routeTable, key=lambda i: i['destinationPrefix'])})
                
            if 'routes' in config_route_table:
                if len(set(config_route_table['routes'].keys())) != len(routeTable_prefixes):
                    # if there are some routes left in config file but deleted from actual route table
                    for prefix in set(config_route_table['routes'].keys()).difference(routeTable_prefixes):
                        # delete route from config file as it does not exist in actual route table
                        config_route_table['routes'].pop(prefix)
                    config_changed = True           

        else:
            print(f"There are no routes in route table {config_route_table['route_table_id']}. Please add at least one route.")
            continue
    
    if all_routeTables:
        # we have a list of all modified route tables 
        # create and launch a thread pool (with 8 max_workers) to execute failover function asynchronously for each modified route table    
        with pool.ThreadPoolExecutor(max_workers=8) as executer:
            try:
                executer.map(failover, all_routeTables)
            except Exception as e:
                print(f"Request to execute failover function failed due to: {e}. Retrying in {cron_interval} seconds...")

    if config_changed:
        # if routes were inserted or deleted from config file need to update it in bucket 
        print(f"Store updated route tables config file in bucket: {config['route_tables']}")
        put_config(config)


def put_config(config, endpoint_url='https://storage.yandexcloud.net'):
    '''
    uploads config file to the bucket
    :param config: configuration dictionary with route tables and load balancer id
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


def failover(route_table):
    '''
    changes next hop in route table by using REST API request to VPC API
    :param route_table: route table is dictionary with route table id, new next hop address and list of static routes
    :return:
    '''
    
    print(f"Updating route table {route_table['route_table_id']} with next hop address {route_table['next_hop']}. New route table: {route_table['routes']}")
    
    try:
        r = requests.patch('https://vpc.api.cloud.yandex.net/vpc/v1/routeTables/%s' % route_table['route_table_id'], json={"updateMask": "staticRoutes", "staticRoutes": route_table['routes'] } ,headers={'Authorization': 'Bearer %s'  % iam_token})
    except Exception as e:
        print(f"Request to update route table {route_table['route_table_id']} failed due to: {e}. Retrying in {cron_interval} seconds...")
        return

    if r.status_code != 200:
        print(f"Unexpected status code {r.status_code} for updating route table {route_table['route_table_id']}. More details: {r.json().get('message')}. Retrying in {cron_interval} seconds...")
        return

    if 'id' in r.json():
        operation_id = r.json()['id']
        print(f"Operation {operation_id} for updating route table {route_table['route_table_id']}. More details: {r.json()}")
    else:
        print(f"Failed to start operation for updating route table {route_table['route_table_id']}. Retrying in {cron_interval} seconds...")


def handler(event, context):
    global iam_token 
    iam_token = context.token['access_token']
    try:    
        config = get_config()
    except Exception as e:
        print(f"Request to get configuration file {path} in bucket failed due to: {e}. Please check that the configuration file exists in bucket {bucket}. Retrying in {cron_interval} seconds...")
        return
    check_router_statuses(config)
