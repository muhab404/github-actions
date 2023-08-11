terraform {
 provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
}

 backend "s3" {
    bucket                  = "terraform-s3-state-muhab"
    key                     = "my-terraform-project"
    region                  = "us-east-1"
    shared_credentials_file = "~/.aws/credentials"
  }
}
