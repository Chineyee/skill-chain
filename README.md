# Skill Chain: Educational Credentials Verification Platform

## Overview
Skill Chain is a decentralized platform built on Stacks blockchain using Clarity smart contracts to manage and verify educational credentials and skills.

## Features
- Create skill credentials with detailed information
- Verify skill credentials
- Transfer skill credential ownership
- Revoke skill credentials
- Track total number of skills

## Contract Functions

### `create-skill-credential`
- Create a new skill credential
- Requires:
  - Skill name (1-100 characters)
  - Description (1-500 characters)
  - Credential URI

### `get-skill-credential`
- Retrieve a specific skill credential
- Requires skill ID and owner address

### `verify-skill-credential`
- Verify the authenticity of a skill credential
- Checks if credential is not revoked

### `transfer-skill-ownership`
- Transfer skill credential to a new owner
- Only original issuer can transfer
- Cannot transfer to self

### `revoke-skill-credential`
- Revoke a previously issued skill credential
- Only original issuer can revoke

## Error Codes
- `ERR-NOT-AUTHORIZED (u100)`: Unauthorized action
- `ERR-SKILL-EXISTS (u101)`: Skill already exists
- `ERR-SKILL-NOT-FOUND (u102)`: Skill not found
- `ERR-INVALID-INPUT (u103)`: Invalid input parameters
- `ERR-TRANSFER-FAILED (u104)`: Skill transfer failed

## Security Considerations
- Owner-based access control
- Input validation
- Prevent self-transfers
- Revocation mechanism

## Deployment
1. Compile the Clarity smart contract
2. Deploy on Stacks blockchain
3. Interact via supported wallets or applications

## Contributing
- Open issues for bugs or feature requests
- Submit pull requests with improvements
- Follow Clarity smart contract best practices
