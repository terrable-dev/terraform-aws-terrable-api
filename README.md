# Terrable Terraform API Module

This Terraform module creates an API Gateway with Lambda integrations for handling HTTP requests.

It is designed to simplify the development of API Gateways, and works in tandem with the Terrable CLI
tooling for an improved local development experience.

## Usage

```hcl
module "example_api" {
  source    = "terrable-dev/terrable-api/aws"
  api_name  = "example-api"
  runtime   = "nodejs20.x"

  handlers = {
    ExampleHandler: {
        source = "./ExampleHandler.ts"
        http = {
          GET = "/"
        }
    }
  }
}
```
