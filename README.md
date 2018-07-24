# terraform-graphql-poc

Proof-of-concept for deploying an app with a GraphQL API using Terraform.

## Getting started

You will need Node.js 8 or later as well as Terraform 0.11.7 or later.

```
npm install
```

To deploy, you'll need to set some parameters and create a security group.

> Note: a few of these steps are annoying. I might create a separate Terraform script for the last few steps. However, I opted to have manual steps instead of encourage folks to spin up a new VPC, subnets, NAT instances, etc. for each project they wish to deploy.

- Visit the AWS console and open "Systems Manager".
- Make sure that your region in the upper-right corner is set to "US East (Ohio)" (us-east-2).
- Click "Parameter Store" on the left-hand sidebar.
- Create and populate the parameters with values from Auth0:
  - `auth0_domain` (String)
  - `auth0_client_id` (String)
  - `auth0_client_secret` (SecureString)
- Make sure your AWS keys are set up and you have enough permissions to deploy everything.
- From the "Services" menu at the top left, open "VPC".
- Make sure that your region in the upper-right corner is set to "US East (Ohio)" (us-east-2).
- Create a new security group called "redis" in the default VPC. This security group should have a single rule, allowing inbound traffic from your VPC's CIDR range on port 6379.
- Make sure that your default security group is named "default".
- Make sure that your default VPC has three public subnets in three different AZs, each with tag "Type" set to "public". Each subnet needs to have a NAT instance.
- Make sure that your default VPC has three private subnets in three different AZs, each with tag "Type" set to "private". Each subnet needs to have its routing table configured to point Internet-bound traffic to the NAT instance in the same AZ.

You're ready to deploy! Run the following commands:

```
bin/task lambda:zip
bin/task terraform init
bin/task terraform apply
```
