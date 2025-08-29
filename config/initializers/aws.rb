require 'aws-sdk-v1'
AWS.config(access_key_id: CRMConfig.s3_access_key, secret_access_key: CRMConfig.s3_secret, region: 'ap-south-1')