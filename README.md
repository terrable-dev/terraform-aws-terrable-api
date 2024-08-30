# Terrable Terraform API Module

This Terraform module creates an API Gateway with Lambda integrations for handling HTTP requests.

It is designed to simplify the development of API Gateways, and works in tandem with the Terrable CLI
tooling for an improved local development experience.

## Usage

```hcl
module "example_api" {
  source = "terrable-dev/terrable-api/aws"
  version = "0.0.1"
  api_name = "example-api"

  handlers = {
    ExampleHandler: {
        source = "./ExampleHandler.ts"
        http = {
          method = "GET"
          path = "/"
        }
    },
  }
}
```
