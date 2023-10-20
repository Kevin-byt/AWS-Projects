# Enforcing MFA in AWS

## Introduction

Welcome to the AWS Multi-Factor Authentication (MFA) Enforcement Guide. This README provides an overview of the steps detailed in the [Enforcing MFA on AWS](https://medium.com/@kevinkiruri/enforcing-mfa-on-aws-66b228df699b), authored by [Kevin Kiruri](https://www.linkedin.com/in/kevin-kiruri/).

## Prerequisites

Before enforcing MFA on your AWS account, make sure you have an AWS account and access to the files within this project.

## Steps

### 1. Create the "Allow Manage Own MFA Device" Policy

- Go to the IAM section on the AWS console.
- Create a policy with the provided JSON.
- Give the policy a name and save.

### 2. Create an IAM User

- Navigate to IAM and create a new user.
- Assign the created policy to the user.
- Create the user with the desired permissions.

### 3. Sign-in to the AWS Console using the New User

- Sign in as the new user.
- Add MFA to the user's account.
- Install an authenticator app.
- Activate MFA and log in again to access AWS resources securely.

## Conclusion

Implementing Multi-Factor Authentication (MFA) is vital for AWS security. Follow these simplified steps to safeguard your AWS account and resources effectively. For the full guide, visit [Enforcing MFA on AWS](https://medium.com/@kevinkiruri/enforcing-mfa-on-aws-66b228df699b).

---

*Author: [Kevin Kiruri](https://www.linkedin.com/in/kevin-kiruri/)*