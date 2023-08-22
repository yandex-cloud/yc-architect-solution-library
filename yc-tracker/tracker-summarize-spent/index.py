import os

from yandex_tracker_client import TrackerClient
client = TrackerClient(token=os.environ['TOKEN'], org_id=os.environ['ORG'])

def handler(event, context):
    issue = client.issues[event['queryStringParameters']['id']]    
    links = issue.links
    if not links:
       exit()
    
    parent_issue_id = ""
    for link in links:
       if link.direction == "inward": # and link.display == "subtask"
         parent_issue_id = link.object.key
         issue_to_update = client.issues[parent_issue_id]  

    last_wl_start = ""
    last_wl_duration = ""
    last_wl_comment = ""
    for wl_record in issue.worklog:
     last_wl_start = wl_record.start
     last_wl_duration = wl_record.duration
     last_wl_comment = str(wl_record.comment)

    issue_to_update.worklog.create (start=last_wl_start, duration=last_wl_duration, comment='automatic added from ' + issue.key)

    return {
        'statusCode': 200,
        'body':  "Ok"
    }
	

