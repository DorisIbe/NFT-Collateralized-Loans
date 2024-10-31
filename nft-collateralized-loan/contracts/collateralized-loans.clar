;; NFT Collateralized Loan Contract
;; Allows users to take loans using their NFTs as collateral

(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-already-listed (err u101))
(define-constant err-not-listed (err u102))
(define-constant err-wrong-price (err u103))
(define-constant err-loan-active (err u104))
(define-constant err-not-borrower (err u105))
(define-constant err-loan-expired (err u106))

;; Data Maps
(define-map loans
    { loan-id: uint }
    {
        borrower: principal,
        lender: (optional principal),
        nft-id: uint,
        collateral-contract: principal,
        loan-amount: uint,
        interest-rate: uint,
        duration: uint,
        start-time: (optional uint),
        status: (string-ascii 20)
    }
)

(define-map nft-loan-index 
    { nft-id: uint, collateral-contract: principal }
    { loan-id: uint }
)

(define-data-var loan-nonce uint u0)


;; Read-only functions
(define-read-only (get-loan (loan-id uint))
    (map-get? loans { loan-id: loan-id })
)

(define-read-only (get-loan-by-nft (nft-id uint) (collateral-contract principal))
    (map-get? nft-loan-index { nft-id: nft-id, collateral-contract: collateral-contract })
)