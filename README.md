# NFT Loan Smart Contract

A decentralized lending protocol built on Stacks blockchain that enables NFT-collateralized loans. Users can borrow STX by using their NFTs as collateral, with built-in mechanisms for loan repayment and default handling.

## Features

- **NFT-Backed Loans**: Use any supported NFT as collateral for STX loans
- **Flexible Loan Terms**: Customizable loan amounts and duration
- **Automated Processing**: Smart contract handles loan creation, repayment, and defaults
- **Secure Collateral Management**: NFTs are held in escrow until loan completion
- **Default Protection**: Automated transfer of collateral to lender upon default

## Smart Contract Functions

### `repay-loan`
Allows borrowers to repay their active loans and retrieve their NFT collateral.
```clarity
(define-public (repay-loan (loan-id uint)) ...)
```
- Verifies loan status and borrower identity
- Processes STX repayment to lender
- Returns NFT collateral to borrower
- Cleans up loan data

### `claim-defaulted-nft`
Enables lenders to claim NFT collateral from defaulted loans.
```clarity
(define-public (claim-defaulted-nft (loan-id uint)) ...)
```
- Verifies loan has defaulted
- Transfers NFT to lender
- Updates loan status to DEFAULTED
- Cleans up NFT locks

### `cancel-loan-request`
Allows borrowers to cancel unfunded loan requests.
```clarity
(define-public (cancel-loan-request (loan-id uint)) ...)
```
- Verifies loan status is OPEN
- Returns NFT to borrower
- Removes loan request data

## Data Structures

### Loan
```clarity
{
  loan-id: uint,
  borrower: principal,
  lender: principal,
  nft-id: uint,
  nft-contract: principal,
  amount: uint,
  end-block: uint,
  status: (string-ascii 10)
}
```

### NFT Lock
```clarity
{
  nft-id: uint,
  nft-contract: principal
}
```

## State Management

The contract maintains two primary maps:
- `loans`: Tracks all loan details
- `nft-locks`: Manages NFT collateral status

## Error Handling

The contract includes comprehensive error checking:
- `err-invalid-loan`: Invalid loan ID or retrieval
- `err-unauthorized`: Unauthorized access attempt
- `err-loan-not-active`: Operations on inactive loans
- `err-loan-expired`: Operations on expired loans
- `err-loan-not-expired`: Premature default claims
- `err-loan-already-active`: Duplicate loan creation

## Requirements

- Stacks 2.4 or higher
- Clarity compatible wallet
- NFT must implement standard transfer function

## Security Considerations

1. **Access Control**
   - Only borrowers can repay loans
   - Only lenders can claim defaulted NFTs
   - Only borrowers can cancel unfunded loans

2. **Timing Constraints**
   - Loans must be repaid before expiration
   - Defaults can only be claimed after expiration
   - Loan cancellation only available before funding

3. **Asset Safety**
   - NFTs are held in contract escrow
   - Atomic transactions for all transfers
   - Protected against reentrancy attacks

## Development and Testing

1. Clone the repository
```bash
git clone https://github.com/DorisIbe/nft-loan-contract
```

2. Install dependencies
```bash
npm install
```

3. Run tests
```bash
npm test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This smart contract is provided as-is. Users should conduct their own security audit before deployment. The authors are not responsible for any losses incurred through the use of this contract.
