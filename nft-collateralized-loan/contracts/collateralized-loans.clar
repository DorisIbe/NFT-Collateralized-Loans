;; NFT Collateralized Loan Contract
;; Allows users to take loans using their NFTs as collateral


(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-nft-owner (err u101))
(define-constant err-nft-locked (err u102))
(define-constant err-invalid-loan (err u103))
(define-constant err-loan-not-active (err u104))
(define-constant err-unauthorized (err u105))
(define-constant err-loan-not-expired (err u106))
(define-constant err-loan-expired (err u107))
(define-constant err-loan-already-active (err u108))
(define-constant err-insufficient-funds (err u109))

;; Data Maps
(define-map loans
    { loan-id: uint }
    {
        borrower: principal,
        lender: (optional principal),
        nft-id: uint,
        nft-contract: principal,
        loan-amount: uint,
        interest-rate: uint,  
        duration: uint,       
        start-block: (optional uint),
        end-block: (optional uint),
        status: (string-ascii 10)  
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

(define-read-only (calculate-repayment-amount (loan-id uint))
    (match (get-loan loan-id)
        loan (let (
                (principal-amount (get loan-amount loan))
                (rate (get interest-rate loan))
                (start-block (unwrap! (get start-block loan) err-loan-not-active))
                (blocks-elapsed (- block-height start-block))
            )
            (ok (+ principal-amount 
                  (/ (* principal-amount rate blocks-elapsed) u10000))))
        err-invalid-loan
    )
)

