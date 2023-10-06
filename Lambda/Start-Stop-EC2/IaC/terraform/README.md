# Terraform

This README provides instructions on how to use Terraform to manage your infrastructure. Terraform is an infrastructure as code (IAC) tool that allows you to define and provision infrastructure resources in a declarative configuration file.

## Prerequisites

Before you begin, make sure you have the following prerequisites installed:

1. **Terraform**: You must have Terraform installed on your local machine.

2. **AWS CLI Credentials**: Set up AWS CLI on your local machine and configure it with your account

## Getting Started

1. Clone this repository to your local machine:

   ```shell
   git clone https://github.com/Kevin-byt/AWS-Projects.git
   cd AWS-Projects/Lambda/Start-Stop-EC2/IaC/terraform
   ```

2. Initialize Terraform by running the following command:

   ```shell
   terraform init
   ```

   This command initializes the working directory and downloads the necessary providers and modules based on your configuration files.

## Terraform Commands

### `terraform validate`
The `terraform validate` command is used to validate the syntax and configuration of your Terraform files without creating an execution plan or making any changes to your infrastructure. It checks for errors and issues in your configuration files.

```shell
terraform validate
```
Running this command is a good practice before running terraform plan or terraform apply to catch any syntax errors or configuration issues early in the process.

### `terraform plan`

The `terraform plan` command is used to create an execution plan. It compares the current state of the infrastructure to the desired state defined in your Terraform configuration files (`.tf` files) and generates an execution plan to show you what changes will be made. It's a dry run and does not make any actual changes to your infrastructure.

```shell
terraform plan
```

### `terraform apply`

The `terraform apply` command is used to apply the changes defined in your configuration files to the infrastructure. It creates, updates, or deletes resources as necessary to match the desired state.

```shell
terraform apply
```

### `terraform destroy`

The `terraform destroy` command is used to destroy all the resources defined in your configuration files. It will prompt you for confirmation before destroying any resources.

```shell
terraform destroy
```

## Usage

1. Edit your Terraform configuration files (`.tf`) to define your infrastructure resources, providers, and variables.

2. Run `terraform validate` to catch any syntax errors or configuration issues

2. Run `terraform plan` to see a preview of the changes that Terraform will make.

3. If the plan looks correct, run `terraform apply` to apply the changes to your infrastructure.

4. To destroy the resources when they are no longer needed, run `terraform destroy`.

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs/index.html): The official Terraform documentation is a comprehensive resource for learning more about Terraform and its features.

- [Terraform Providers](https://registry.terraform.io/browse/providers): The Terraform Provider Registry contains documentation and examples for various cloud and infrastructure providers.

- [Terraform Community](https://community.hashicorp.com/c/terraform/7): Join the Terraform community forum to ask questions and share your experiences with Terraform.

## Conclusion

Terraform is a powerful tool for managing infrastructure as code. By following the instructions in this README and referring to the official documentation, you can effectively use Terraform to define, provision, and manage your infrastructure resources.