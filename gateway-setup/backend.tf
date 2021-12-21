terraform {
    backend "s3" {
        bucket = "tf-state-bucket-for-api-gateway"
        key = "gw/terraform.tfstate"
        region = "us-east-2"

        dynamodb_table = "tf_lock_api_gateway"
    }
}
