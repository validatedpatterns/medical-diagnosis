import json
import os

import boto3

bucket_base_name = os.environ["bucket_base_name"]
kafka_endpoint = os.environ["kafka_endpoint"]
aws_access_key_id = os.environ["AWS_ACCESS_KEY_ID"]
aws_secret_access_key = os.environ["AWS_SECRET_ACCESS_KEY"]
endpoint_url = os.environ["endpoint_url"]

s3 = boto3.client(
    "s3",
    endpoint_url=endpoint_url,
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    region_name="default",
)

sns = boto3.client(
    "sns",
    endpoint_url=endpoint_url,
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    region_name="default",
)


def create_bucket(bucket_name):
    # ceph rgw create_bucket
    # returns 200 if the bucket exists, and owned by this user
    # and also when the bucket was successfully created
    res = s3.create_bucket(Bucket=bucket_name)
    if res["ResponseMetadata"]["HTTPStatusCode"] == 200:
        print(
            f"Bucket {bucket_name} was created or already existing and owned by this user."
        )
        return
    print(f"There was an error during creating bucket: {bucket_name}: {res}")
    exit(1)


create_bucket(bucket_base_name)
create_bucket(bucket_base_name + "-processed")
create_bucket(bucket_base_name + "-anonymized")


for bucket in s3.list_buckets()["Buckets"]:
    bucket_policy_dict = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AddPerm",
                "Effect": "Allow",
                "Principal": "*",
                "Action": ["s3:GetObject"],
                "Resource": ["arn:aws:s3:::{0}/*".format(bucket["Name"])],
            }
        ],
    }
    bucket_policy = json.dumps(bucket_policy_dict)
    s3.put_bucket_policy(Bucket=bucket["Name"], Policy=bucket_policy)

attributes = {}
attributes["push-endpoint"] = f"kafka://{kafka_endpoint}"
attributes["kafka-ack-level"] = "broker"


def create_topic(topic):
    res = sns.create_topic(Name=topic, Attributes=attributes)
    if res["ResponseMetadata"]["HTTPStatusCode"] == 200:
        print(f"SNS topic: {topic} was created or already existing.")
        return res["TopicArn"]
    print(f"There was an error during creating SNS topic: {topic}: {res}")
    exit(1)


topic_arn = create_topic("xray-images")

bucket_notifications_configuration = {
    "TopicConfigurations": [
        {"Id": "xray-images", "TopicArn": topic_arn, "Events": ["s3:ObjectCreated:*"]}
    ]
}

res = s3.put_bucket_notification_configuration(
    Bucket=bucket_base_name,
    NotificationConfiguration=bucket_notifications_configuration,
)

if res["ResponseMetadata"]["HTTPStatusCode"] == 200:
    print(
        f"Notification for bucket: {bucket_base_name} was created or already existing."
    )
else:
    print(
        f"There was an error during creating notification for bucket: {bucket_base_name}: {res}"
    )
    exit(1)
