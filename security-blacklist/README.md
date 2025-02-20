# Blacklist Manager Smart Contract

## Overview
The Blacklist Manager Smart Contract is a Clarity-based contract designed to maintain and manage a blacklist of addresses on the Stacks blockchain. It provides comprehensive functionality for administrators to manage restricted addresses, handle removal requests, and maintain the integrity of the blacklisting system.

## Features
- Address blacklisting with customizable duration and severity levels
- Multi-level administrative control
- Blacklist removal request system
- Detailed blacklist status tracking
- Contract operational status management
- Prevention of unauthorized STX transfers

## Administrative Structure
- Primary Contract Administrator
- Secondary Contract Administrator
- Regular Administrators

## Error Codes
- `ERR-UNAUTHORIZED-ACCESS (u100)`: Access denied due to insufficient permissions
- `ERR-ADDRESS-ALREADY-BLACKLISTED (u101)`: Address is already on the blacklist
- `ERR-ADDRESS-NOT-BLACKLISTED (u102)`: Address is not found on the blacklist
- `ERR-INVALID-INPUT-PARAMETER (u103)`: Invalid input parameters provided
- `ERR-BULK-OPERATION-FAILED (u104)`: Bulk operation execution failed
- `ERR-ADMIN-PERMISSION-REQUIRED (u105)`: Administrator permissions required
- `ERR-CANNOT-BLACKLIST-ADMINISTRATOR (u106)`: Cannot blacklist an administrator
- `ERR-INVALID-TIMESTAMP (u107)`: Invalid timestamp provided
- `ERR-BLACKLIST-PERIOD-EXPIRED (u108)`: Blacklist period has expired

## Main Functions

### Administrative Functions
1. `update-primary-administrator`: Update the primary administrator address
2. `update-secondary-administrator`: Update the secondary administrator address
3. `register-administrator`: Add a new administrator
4. `deregister-administrator`: Remove an administrator
5. `toggle-contract-operations`: Enable/disable contract operations

### Blacklist Management
1. `add-to-blacklist`: Add an address to the blacklist with:
   - Custom reason
   - Restriction level (1-10)
   - Optional duration
2. `remove-from-blacklist`: Remove an address from the blacklist
3. `update-blacklist-duration`: Modify the blacklist duration for an address

### Removal Request System
1. `submit-removal-request`: Submit a request to be removed from the blacklist
2. `review-removal-request`: Review and approve/reject removal requests

### Read-Only Functions
1. `check-address-blacklist-status`: Check if an address is blacklisted
2. `get-address-blacklist-information`: Get detailed blacklist information
3. `get-blacklist-justification`: Get the reason for blacklisting
4. `get-blacklist-total-count`: Get total number of blacklisted addresses
5. `check-administrator-status`: Check if an address is an administrator
6. `get-removal-request-status`: Check status of removal requests
7. `get-contract-details`: Get contract operational details

## Data Storage
- `blacklist-registry`: Stores blacklist status and details
- `blacklist-justifications`: Stores reasons for blacklisting
- `administrator-registry`: Tracks administrator addresses
- `blacklist-removal-requests`: Manages removal requests

## Security Features
- Authorization checks for all administrative functions
- Prevention of administrator blacklisting
- Input validation for all parameters
- STX transfer prevention to contract
- Operational status toggle for emergency situations

## Usage Guidelines

### For Administrators
1. Always provide clear justifications when blacklisting addresses
2. Set appropriate restriction severity levels (1-10)
3. Review removal requests in a timely manner
4. Maintain accurate documentation of administrative actions

### For Users
1. Check blacklist status before transactions
2. Submit detailed justifications for removal requests
3. Monitor blacklist duration and status

## Best Practices
1. Regularly review and update blacklist entries
2. Maintain clear communication channels for removal requests
3. Document all administrative actions
4. Regularly verify administrator access and permissions
5. Monitor contract operational status

## Technical Requirements
- Stacks blockchain compatibility
- Clarity smart contract language
- Principal address format for all addresses

## Limitations
- Fixed restriction severity range (1-10)
- Maximum justification length of 500 characters
- Single removal request per address