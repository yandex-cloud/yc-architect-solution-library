import os
import logging
import requests

from typing import List
from datetime import datetime, timedelta
from isoduration import parse_duration

import pandas as pd

TRACKER_API_ISSUES_URL = 'https://api.tracker.yandex.net/v2/issues'
TRACKER_ORG_ID = os.environ['TRACKER_ORG_ID']
TRACKER_TOKEN = os.environ['TRACKER_OAUTH_TOKEN']

TRACKER_HEADERS = {
    'X-Org-ID': TRACKER_ORG_ID,
    'Authorization': 'OAuth ' + TRACKER_TOKEN,
}

TRACKER_INITIAL_HISTORY_DEPTH = os.environ.get('TRACKER_INITIAL_HISTORY_DEPTH')

# ClickHouse params
CH_URL = f'https://{os.environ["CH_HOST"]}:8443/?database={os.environ["CH_DB"]}'
AUTH = {
    'X-ClickHouse-User': os.environ['CH_USER'],
    'X-ClickHouse-Key': os.environ['CH_PASSWORD'],
}

CERT = '/etc/ssl/certs/ca-certificates.crt'
CH_ISSUES_TABLE = os.environ['CH_ISSUES_TABLE']
CH_CHANGELOG_TABLE = os.environ['CH_CHANGELOG_TABLE']
CH_STATUSES_VIEW = os.environ['CH_STATUSES_VIEW']

# Columns to load into database
ISSUES_COLUMNS = [
    'organization_id',
    'id',
    'key',
    'version',
    'storyPoints',
    'summary',
    'statusStartTime',
    'boards_names',
    'createdAt',
    'commentWithoutExternalMessageCount',
    'votes',
    'commentWithExternalMessageCount',
    'deadline',
    'updatedAt',
    'favorite',
    'updatedBy_display',
    'type_display',
    'priority_display',
    'createdBy_display',
    'assignee_display',
    'queue_key',
    'queue_display',
    'status_display',
    'previousStatus_display',
    'parent_key',
    'parent_display',
    'components_display',
    'sprint_display',
    'epic_display',
    'previousStatusLastAssignee_display',
    'originalEstimation',
    'spent',
    'tags',
    'estimation',
    'checklistDone',
    'checklistTotal',
    'emailCreatedBy',
    'sla',
    'emailTo',
    'emailFrom',
    'lastCommentUpdatedAt',
    'followers',
    'pendingReplyFrom',
    'end',
    'start',
    'project_display',
    'votedBy_display',
    'aliases',
    'previousQueue_display',
    'access',
    'resolvedAt',
    'resolvedBy_display',
    'resolution_display',
    'lastQueue_display',
]

ISSUE_CHANGELOG_COLUMNS = [
    'organization_id',
    'id',
    'issue_key',
    'updatedAt',
    'updatedBy_display',
    'type',
    'field_display',
    'from_display',
    'to_display',
    'worklog',
]


def datetime_from_str(dt_str):
    return datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S")


def datetime_to_str(dt):
    return str(dt)


def get_issues_query_text():
    """
    Get the latest record which has been loaded to tracker_issues table:
    Returns:
        json object with records
    """
    # Get latest updated issue form database
    get_max_uploaded_at_query = f'select MAX(updatedAt) from {CH_ISSUES_TABLE}'
    response = run_clickhouse_query(get_max_uploaded_at_query)
    latest_record_time = datetime_from_str(response[:-5])
    min_dt = datetime_from_str('1970-01-01 03:00:00')

    if latest_record_time > min_dt:
        # subtract 5 minutes to handle possible time overlapping & late updates
        start_time = datetime_to_str(latest_record_time - timedelta(minutes=5))
        tracker_query_text = 'updated: > "' + start_time + '"'
        return tracker_query_text
    elif TRACKER_INITIAL_HISTORY_DEPTH:
        tracker_query_text = 'updated: >now()-' + TRACKER_INITIAL_HISTORY_DEPTH
        return tracker_query_text
    else:
        return 'updated: >now() - 1y'


def get_tracker_issues(query_text):
    """
    Load issue list from Yandex Tracker using scroll method, see doc:
    https://cloud.yandex.ru/docs/tracker/concepts/issues/search-issues#scroll

    Arguments:
        query_text (str): Yandex Tracker query for search issues
    Returns:
        json object with records
    """
    # Query to filter Tracker issues
    query_body = {'query': query_text}

    # Make Tracker API call
    response = requests.post(
        f'{TRACKER_API_ISSUES_URL}/_search?scrollType=unsorted&perScroll=100&scrollTTLMillis=60000',
        headers=TRACKER_HEADERS,
        json=query_body
    )

    issues = response.json()

    # loop wile number of collected data less than total records in query result
    while len(issues) < int(response.headers['X-Total-Count']):
        scroll_id = response.headers['X-Scroll-Id']
        scroll_token = response.headers['X-Scroll-Token']
        query_url = f"{query_url_base}?scrollId={scroll_id}&scrollToken={scroll_token}"
        issues.extend(requests.post(query_url, headers=TRACKER_HEADERS, json=query_body).json())

    logging.info('Tracker data loaded, total records: %d', len(issues))
    return issues


def get_tracker_issue_changelog_for_key(issue_key):
    """
    Load issue changelog from Yandex Tracker using scroll method, see doc:
    https://cloud.yandex.ru/docs/tracker/concepts/issues/search-issues#scroll

    Arguments:
        issue_key (str): issue key
    Returns:
        json object with records
    """
    query_url = f"{TRACKER_API_ISSUES_URL}/{issue_key}/changelog?perPage=50&type=IssueWorkflow"

    # Make Tracker API call
    response = requests.get(query_url, headers=TRACKER_HEADERS)
    changelogs = response.json()

    # loop through all response pages
    while 'next' in response.links:
        query_url = response.links['next']['url']
        response = requests.get(query_url, headers=TRACKER_HEADERS)
        changelogs.extend(response.json())

    logging.info(f'Issue %s history data loaded, total records: %s', issue_key, len(changelogs))
    return changelogs


def get_tracker_issues_changelog(issues):
    """
    Collect changelog for issues represented in json

    Arguments:
        issues (json): list of issues
    Returns:
        Pandas json object with records
    """
    changelog_json = []
    for issue in issues:
        changelog_json.extend(get_tracker_issue_changelog_for_key(issue['key']))

    return changelog_json


def convert_list_to_dataframe(l):
    raw_df = pd.json_normalize(l, sep='_', max_level=2)
    raw_df.insert(0, 'organization_id', TRACKER_ORG_ID)
    return raw_df


def refine_datetime_values(data, dt_columns):
    for record in data:
        for col in dt_columns:
            data[col] = pd.to_datetime(data[col]).dt.tz_localize(None).fillna('1970-01-01 00:00:00.000')
            # apply Lambda fuction to each datetime column to unify datetime sting representation - trim tast 3 symbols of microseconds
            data[col] = data[col].apply(lambda x: x.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3])


def shape_issues_data(issues):
    """
    Convert issues to Pandas dataframe and add 'org_id' column

    Arguments:
        issues (json): input JSON data
    Returns:
        Pandas dataframe object with records
    """

    raw_df = convert_list_to_dataframe(issues)

    def to_str(o, col_name):
        if isinstance(o, list):
            return ', '.join([i[col_name] for i in o])
        return o

    def format_boards_column(item):
        return to_str(item, 'name')

    def format_components_column(item):
        return to_str(item, 'display')

    def format_sprint_column(item):
        return to_str(item, 'display')

    def calculate_iso8601_duration(item):
        try:
            duration_obj = parse_duration(item)
            duration = duration_obj.date.years * 60 * 8 * 20 * 12 + duration_obj.date.months * 60 * 8 * 20
            duration += duration_obj.date.days * 60 * 8 + duration_obj.date.weeks * 60 * 40
            duration += duration_obj.time.hours * 60 + duration_obj.time.minutes
        except TypeError:
            duration = 0
        return duration

    if 'boards' in raw_df:
        raw_df['boards_names'] = raw_df['boards'].apply(format_boards_column)

    if 'components' in raw_df:
        raw_df['components_display'] = raw_df['components'].apply(format_components_column)

    if 'sprint' in raw_df:
        raw_df['sprint_display'] = raw_df['sprint'].apply(format_sprint_column)

    if 'originalEstimation' in raw_df:
        raw_df['originalEstimation'] = raw_df['originalEstimation'].apply(calculate_iso8601_duration)

    if 'spent' in raw_df:
        raw_df['spent'] = raw_df['spent'].apply(calculate_iso8601_duration)

    if 'estimation' in raw_df:
        raw_df['estimation'] = raw_df['estimation'].apply(calculate_iso8601_duration)

    # filter out unnecessary colums
    shaped_df = pd.DataFrame(columns=ISSUES_COLUMNS)
    for column in ISSUES_COLUMNS:
        shaped_df[column] = raw_df.get(column, "")

    # reformat dateTime columns
    # List of columns with dateTime data format
    date_time_columns = [
        'statusStartTime',
        'createdAt',
        'updatedAt',
        'lastCommentUpdatedAt',
        'start',
        'end',
        'resolvedAt'
    ]

    # Round dateTime columns up to seconds
    refine_datetime_values(shaped_df, date_time_columns)

    # reformat decimal columns
    # List of columns with decimal data format
    decimal_columns = [
        'storyPoints',
        'commentWithExternalMessageCount',
        'commentWithoutExternalMessageCount',
        'votes',
        'checklistDone',
        'checklistTotal'
    ]
    # Round dateTime columns up to 2 digits after comma
    for column in decimal_columns:
        shaped_df[column] = pd.to_numeric(shaped_df[column]).round(10)

    return shaped_df


def shape_issue_changelog_data(changelogs):
    """
    Convert issues changelog json data to Pandas dataframe

    Arguments:
        changelogs (json): input JSON data
    Returns:
        Pandas dataframe object with records
    """
    raw_df = convert_list_to_dataframe(changelogs)

    # expand list in the 'fields' field to duplicate rows
    raw_df = raw_df.explode('fields')

    # get (fields -> field -> display) data
    def get_field_display(item):
        return item['field'].get('display')

    def get_subfield_display(item, subfield_name):
        if item['field']['id'] in ['status', 'resolution', 'assignee'] and item.get(subfield_name):
            return item[subfield_name].get('display', item[subfield_name])
        return ''

    # get (fields -> from -> display) data
    def get_from_display(item):
        return get_subfield_display(item, 'from')

    # get (fields -> to -> display) data
    def get_to_display(item):
        return get_subfield_display(item, 'to')

    raw_df['field_display'] = raw_df['fields'].apply(get_field_display)
    raw_df['from_display'] = raw_df['fields'].apply(get_from_display)
    raw_df['to_display'] = raw_df['fields'].apply(get_to_display)

    # filter our unnecessary columns
    shaped_df = pd.DataFrame(columns=ISSUE_CHANGELOG_COLUMNS)
    for col in ISSUE_CHANGELOG_COLUMNS:
        try:
            shaped_df[col] = raw_df[col]
        except KeyError:
            shaped_df[col] = ''

    # reformat dateTime columns
    # List of columns with dateTime data format
    date_time_columns: List[str] = [
        'updatedAt'
    ]
    refine_datetime_values(shaped_df, date_time_columns)

    return shaped_df


def init_database(drop_table=False):
    """
    Initialise Clickhouse DB: Dropping & CReating table with columns

    Arguments:
        drop_table (Boleean): flag to indcate tha Dropping table is needed
    Returns:
        Nothing
    """
    if drop_table:
        run_clickhouse_query(f"drop table if exists {CH_ISSUES_TABLE};")

    create_issues_table_query = f'''
        CREATE TABLE IF NOT EXISTS {os.environ['CH_DB']}.{CH_ISSUES_TABLE}
        (
            organization_id                     String,
            self                                String,
            id                                  String,
            key                                 String,
            version                             String,
            storyPoints                         Decimal(15,2),
            summary                             String,
            statusStartTime                     DateTime64(3, 'Europe/Moscow'),
            boards_names                        String,
            createdAt                           DateTime64(3, 'Europe/Moscow'),
            commentWithoutExternalMessageCount  Decimal(15,2),
            votes                               Decimal(15,2),
            commentWithExternalMessageCount     Decimal(15,2),
            deadline                            String,
            updatedAt                           DateTime64(3, 'Europe/Moscow'),
            favorite                            String,
            updatedBy_display                   String,
            type_display                        String,
            priority_display                    String,
            createdBy_display                   String,
            assignee_display                    String,
            queue_key                           String,
            queue_display                       String,
            status_display                      String,
            previousStatus_display              String,
            parent_key                          String,
            parent_display                      String,
            components_display                  String,
            sprint_display                      String,
            epic_display                        String,
            previousStatusLastAssignee_display  String,
            originalEstimation                  Decimal(15,2),
            spent                               Decimal(15,2),
            tags                                String,
            estimation                          Decimal(15,2),
            checklistDone                       Decimal(15,2),
            checklistTotal                      Decimal(15,2),
            emailCreatedBy                      String,
            sla                                 String,
            emailTo                             String,
            emailFrom                           String,
            lastCommentUpdatedAt                DateTime64(3, 'Europe/Moscow'),
            followers                           String,
            pendingReplyFrom                    String,
            end                                 DateTime64(3, 'Europe/Moscow'),
            start                               DateTime64(3, 'Europe/Moscow'),
            project_display                     String,
            votedBy_display                     String,
            aliases                             String,
            previousQueue_display               String,
            access                              String,
            resolvedAt                          DateTime64(3, 'Europe/Moscow'),
            resolvedBy_display                  String,
            resolution_display                  String,
            lastQueue_display                   String
        )
        ENGINE = ReplacingMergeTree()  
        ORDER BY (id) 
        '''
    run_clickhouse_query(create_issues_table_query)

    # issues changelog data
    if drop_table:
        run_clickhouse_query(f'drop table if exists {CH_CHANGELOG_TABLE};')

    create_changelog_table_query = f'''
        CREATE TABLE IF NOT EXISTS {os.environ['CH_DB']}.{CH_CHANGELOG_TABLE}
        (
            organization_id                     String,
            id                                  String,
            issue_key                           String,
            updatedAt                           DateTime64(3, 'Europe/Moscow'),
            updatedBy_display                   String,
            type                                String,
            field_display                       String,
            from_display                        String,
            to_display                          String,
            worklog                             String
        )
        ENGINE = ReplacingMergeTree()  
        ORDER BY (id, field_display) 
        '''
    run_clickhouse_query(create_changelog_table_query)

    create_issues_view = '''
        CREATE OR REPLACE VIEW {db}.v_{table} AS
        SELECT organization_id, `self`, id, `key`, version, storyPoints, 
        summary, statusStartTime, boards_names, createdAt, 
        commentWithoutExternalMessageCount, votes, 
        commentWithExternalMessageCount, deadline, updatedAt, favorite, 
        updatedBy_display, type_display, priority_display, 
        createdBy_display, assignee_display, queue_key, queue_display, 
        status_display, previousStatus_display, parent_key, parent_display, 
        components_display, sprint_display, epic_display, 
        previousStatusLastAssignee_display, originalEstimation, spent, 
        tags, estimation, checklistDone, checklistTotal, emailCreatedBy,
        sla, emailTo, emailFrom, lastCommentUpdatedAt, followers, 
        pendingReplyFrom, `end`, `start`, project_display, 
        votedBy_display, aliases, previousQueue_display, access, 
        resolvedAt, resolvedBy_display, resolution_display, 
        lastQueue_display
        FROM (
            SELECT organization_id, `self`, id, `key`, version, storyPoints, 
            summary, statusStartTime, boards_names, createdAt, 
            commentWithoutExternalMessageCount, votes, 
            commentWithExternalMessageCount, deadline, updatedAt, favorite, 
            updatedBy_display, type_display, priority_display, 
            createdBy_display, assignee_display, queue_key, queue_display, 
            status_display, previousStatus_display, parent_key, parent_display, 
            components_display, sprint_display, epic_display, 
            previousStatusLastAssignee_display, originalEstimation, spent, 
            tags, estimation, checklistDone, checklistTotal, emailCreatedBy,
            sla, emailTo, emailFrom, lastCommentUpdatedAt, followers, 
            pendingReplyFrom, `end`, `start`, project_display, 
            votedBy_display, aliases, previousQueue_display, access, 
            resolvedAt, resolvedBy_display, resolution_display, 
            lastQueue_display,
            row_number() over (partition by id order by updatedAt desc) as lvl
            FROM {db}.{table}
        ) T WHERE T.lvl = 1;
    '''
    create_issues_view = create_issues_view.format(db=os.environ['CH_DB'], table=CH_ISSUES_TABLE)
    run_clickhouse_query(create_issues_view)

    create_changelog_view = '''
        CREATE OR REPLACE VIEW v_{table} AS
        SELECT id, issue_key, updatedAt, updatedBy_display, `type`,
        field_display, from_display, to_display, worklog
        FROM (
            SELECT organization_id, id, issue_key, updatedAt, updatedBy_display, `type`,
            field_display, from_display, to_display, worklog,
            row_number() over (partition by organization_id, id, field_display order by updatedAt desc) as lvl
            FROM {db}.{table}
        ) T WHERE T.lvl = 1;
    '''
    create_changelog_view = create_changelog_view.format(db=os.environ['CH_DB'], table=CH_CHANGELOG_TABLE)
    run_clickhouse_query(create_changelog_view)

    create_open_issues_view = '''
        create or replace view {db}.{view} as (
            select c.issue_key as issue_key,
            i.createdAt as issueCreated,
            c2.updatedAt as fromStatusTimestamp,
            c.updatedAt as toStatusTimestamp,
            if (
                c.from_display = 'Открыт'
                and year(c2.updatedAt) = 1970,
                (toUnixTimestamp(c.updatedAt) - toUnixTimestamp(i.createdAt))/60,
                (
                toUnixTimestamp(c.updatedAt) - toUnixTimestamp(c2.updatedAt)
                ) / 60
            ) as fromPrevious,
            c.from_display as fromStatus,
            c.to_display as toStatus
            ,(
                toUnixTimestamp(c.updatedAt) - toUnixTimestamp(i.createdAt)
            ) / 60 as fromCreated
            from {db}.{changelogs_table} c
            join {db}.{issues_table} i on c.issue_key = i.key asof
            left join {db}.{changelogs_table} c2 on c.issue_key = c2.issue_key
            and c.type = c2.type
            and c.field_display = c2.field_display
            and c.updatedAt > c2.updatedAt
            where c.type = 'IssueWorkflow'
            and c.field_display = 'Статус'
            order by c.issue_key,
            c.updatedAt
        ) settings join_use_nulls = 1
    '''
    create_open_issues_view = create_open_issues_view.format(
        db=os.environ['CH_DB'],
        view=os.environ['CH_STATUSES_VIEW'],
        changelogs_table=CH_CHANGELOG_TABLE,
        issues_table=CH_ISSUES_TABLE,
    )
    run_clickhouse_query(create_open_issues_view)


def run_clickhouse_query(query, connection_timeout=1500):
    """
    Exec clickhouse query

    Arguments:
        query (string): Query string
    Returns:
        response from database
    """
    url = 'https://{host}:8443/?database={db}'.format(
        host=os.environ['CH_HOST'],
        db=os.environ['CH_DB']
    )
    # Run Clickhouse query, places in the body of POST request (Query string could be long and not fit in url string)
    response = requests.post(url, data=query.encode('utf-8'), headers=AUTH, verify=CERT, timeout=connection_timeout)
    if response.status_code == 200:
        return response.text
    else:
        raise ValueError(response.text)


def upload_clickhouse_data(data, table_name):
    """
    Exec clickhouse query

    Arguments:
        data (string): Data to be uploaded in CSV format
        table_name (string): destination table name
    Returns:
        response from database
    """

    query_dict = {
        'query': f'INSERT INTO {table_name} FORMAT TabSeparatedWithNames'
    }
    response = requests.post(CH_URL, data=data, params=query_dict, headers=AUTH, verify=CERT)
    result = response.text
    if response.status_code == 200:
        return result
    else:
        print(response.text)
        raise ValueError(response.text)


def upload_data_to_db(issues_df, changelog_df):
    """
    Upload two dataframes to database

    Arguments:
        issues_df (Dataframe): dataframe with tracker data
        changelog_df (Dataframe): dataframe with issues changelog data
    Returns:
        Nothing
    """

    # Prepare issues data to upload: escaping \n to allow fields with new lines be represented correctly in CSV format
    issues_content = issues_df.replace("\n", "\\\n", regex=True).to_csv(index=False, sep='\t')
    issues_content = issues_content.encode('utf-8')
    # Prepare changelog data to upload: escaping \n to allow fields with new lines be represented correctly in CSV format
    changelog_content = changelog_df.replace("\n", "\\\n", regex=True).to_csv(index=False, sep='\t')
    changelog_content = changelog_content.encode('utf-8')
    upload_clickhouse_data(issues_content, CH_ISSUES_TABLE)
    upload_clickhouse_data(changelog_content, CH_CHANGELOG_TABLE)


def setup_logging():
    logging.getLogger().setLevel(logging.INFO)


def handler(*args, **kwargs):
    setup_logging()
    logging.info("Starting loading issues")
    init_database(drop_table=False)
    query = get_issues_query_text()
    issues = get_tracker_issues(query)
    issues_chagelogs = get_tracker_issues_changelog(issues)
    logging.info("Finished loading issues")

    upload_data_to_db(shape_issues_data(issues), shape_issue_changelog_data(issues_chagelogs))

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/plain'
        },
        'isBase64Encoded': False,
        'body': 'OK',
    }


if __name__ == "__main__":
    handler()
