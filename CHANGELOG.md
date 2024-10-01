## 0.1.0

## 1.1.3

### Patch Changes

- 967db7f: Fix version constraint for the Common Fate Terraform provider to allow minor version updates.

## 1.1.2

### Patch Changes

- a335783: Added the ability to specify an override for the rds endpoint per rds user to allow read roles to use a read only replica endpoint.

## 1.1.1

### Patch Changes

- a94c200: Allow the rds_security_group_id to be empty when create_security_group_rule is false.

## 1.1.0

### Minor Changes

- 55ab27b: Allow creation of the security group rule to be disabled, by setting the 'create_security_group_rule' variable to false.

## 1.0.1

### Patch Changes

- 055652f: Provide the current aws account id when registering the database resource with the Common Fate API. The account and region must match the Proxy integration.

## 1.0.0

### Major Changes

- 908b21c: This module us used to register an RDS database and users with Common Fate in conjunction with an AWS RDS Proxy.

## 0.2.0

### Minor Changes

- 85a8d4d: Initial release

### Minor Changes

- dc0f43b: inital version
