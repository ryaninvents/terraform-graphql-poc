# terraform-graphql-poc

Proof-of-concept for deploying an app with a GraphQL API using Terraform.

## Getting started

You will need Node.js 8 or later as well as Terraform 0.11.7 or later.

```
npm install
```

To deploy, you'll need to set some parameters.

- Visit the AWS console and open "Systems Manager".
- Make sure that your region in the upper-right corner is set to "US East (Ohio)" (us-east-2).
- Click "Parameter Store" on the left-hand sidebar.
- Create and populate the parameters with values from Auth0:
  - `auth0_domain` (String)
  - `auth0_client_id` (String)
  - `auth0_client_secret` (SecureString)
- Make sure your AWS keys are set up and you have enough permissions to deploy everything.

You're ready to deploy! Run the following commands:

```
bin/task terraform init
bin/task terraform apply
```
