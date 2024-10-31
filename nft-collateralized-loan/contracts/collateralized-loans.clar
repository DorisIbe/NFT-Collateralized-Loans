;; NFT Collateralized Loan Contract
;; Allows users to take loans using their NFTs as collateral

(define-trait nft-trait
    (
        (transfer (uint principal principal) (response bool uint))
        (get-owner (uint) (response (optional principal) uint))
    )
)


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

(define-map nft-locks
    { nft-id: uint, nft-contract: principal }
    { loan-id: uint }
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

(define-read-only (get-nft-lock (nft-id uint) (nft-contract principal))
    (map-get? nft-locks { nft-id: nft-id, nft-contract: nft-contract })
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

;; Public functions
(define-public (create-loan-request 
    (nft-contract <nft-trait>) 
    (nft-id uint)
    (loan-amount uint)
    (interest-rate uint)
    (duration uint))
    (let (
        (loan-id (var-get loan-nonce))
        (nft-contract-principal (contract-of nft-contract))
    )
        ;; Check if NFT is owned by sender
        (match (contract-call? nft-contract get-owner nft-id)
            success 
                (if (is-eq (some tx-sender) success)
                    (begin
                        ;; Check if NFT is not already locked
                        (asserts! (is-none (get-nft-lock nft-id nft-contract-principal)) err-nft-locked)
                        
                        ;; Transfer NFT to contract
                        (try! (contract-call? nft-contract transfer 
                            nft-id 
                            tx-sender 
                            (as-contract tx-sender)))
                        
                        ;; Create loan
                        (map-set loans
                            { loan-id: loan-id }
                            {
                                borrower: tx-sender,
                                lender: none,
                                nft-id: nft-id,
                                nft-contract: nft-contract-principal,
                                loan-amount: loan-amount,
                                interest-rate: interest-rate,
                                duration: duration,
                                start-block: none,
                                end-block: none,
                                status: "OPEN"
                            })
                        
                        ;; Lock NFT
                        (map-set nft-locks
                            { nft-id: nft-id, nft-contract: nft-contract-principal }
                            { loan-id: loan-id })
                        
                        ;; Increment nonce
                        (var-set loan-nonce (+ loan-id u1))
                        (ok loan-id)
                    )
                    err-not-nft-owner)
            error (err error))
    )
)

(define-public (fund-loan (loan-id uint))
    (let (
        (loan (unwrap! (get-loan loan-id) err-invalid-loan))
        (current-block block-height)
    )
        ;; Verify loan status
        (asserts! (is-eq (get status loan) "OPEN") err-loan-already-active)
        
        ;; Transfer STX from lender to borrower
        (try! (stx-transfer? (get loan-amount loan) tx-sender (get borrower loan)))
        
        ;; Update loan status
        (map-set loans
            { loan-id: loan-id }
            (merge loan {
                lender: (some tx-sender),
                start-block: (some current-block),
                end-block: (some (+ current-block (get duration loan))),
                status: "ACTIVE"
            }))
        (ok true)
    )
)

;; Repay loan function
(define-public (repay-loan (loan-id uint))
  (let
    (
      (loan (unwrap! (get-loan loan-id) err-invalid-loan))
      (repayment-amount (unwrap! (calculate-repayment-amount loan-id) err-invalid-loan))
    )
    ;; Verify loan status and borrower
    (asserts! (is-eq (get status loan) "ACTIVE") err-loan-not-active)
    (asserts! (is-eq tx-sender (get borrower loan)) err-unauthorized)
    (asserts! (<= block-height (unwrap! (get end-block loan) err-invalid-loan)) err-loan-expired)

    ;; Transfer repayment to lender
    (try! (stx-transfer? repayment-amount tx-sender (unwrap! (get lender loan) err-invalid-loan)))

    ;; Return NFT - Now with fully qualified contract name
    (as-contract 
      (try! 
        (contract-call? 
          .nft-marketplace  ;; Replace with actual contract name like .wrapped-bitcoin or .punk-transfer
          transfer 
          (get nft-id loan) 
          contract-address
          (get borrower loan)
        )
      )
    )

    ;; Clear loan data
    (map-delete loans loan-id)
    (map-delete nft-locks 
      {
        nft-id: (get nft-id loan),
        nft-contract: (get nft-contract loan)
      }
    )
    (ok true)
  )
)

;; Claim defaulted NFT function
(define-public (claim-defaulted-nft (loan-id uint))
  (let
    (
      (loan (unwrap! (get-loan loan-id) err-invalid-loan))
    )
    ;; Verify loan status and caller
    (asserts! (is-eq (get status loan) "ACTIVE") err-loan-not-active)
    (asserts! (is-eq tx-sender (unwrap! (get lender loan) err-invalid-loan)) err-unauthorized)
    (asserts! (>= block-height (unwrap! (get end-block loan) err-invalid-loan)) err-loan-not-expired)

    ;; Transfer NFT to lender - Now with fully qualified contract name
    (as-contract 
      (try! 
        (contract-call? 
          .nft-marketplace  ;; Replace with actual contract name
          transfer 
          (get nft-id loan) 
          contract-address
          (get lender loan)
        )
      )
    )

    ;; Update loan status
    (map-set loans loan-id (merge loan { status: "DEFAULTED" }))
    
    ;; Clear NFT lock
    (map-delete nft-locks 
      {
        nft-id: (get nft-id loan),
        nft-contract: (get nft-contract loan)
      }
    )
    (ok true)
  )
)

;; Cancel loan request function
(define-public (cancel-loan-request (loan-id uint))
  (let
    (
      (loan (unwrap! (get-loan loan-id) err-invalid-loan))
    )
    ;; Verify loan status and caller
    (asserts! (is-eq (get status loan) "OPEN") err-loan-already-active)
    (asserts! (is-eq tx-sender (get borrower loan)) err-unauthorized)

    ;; Return NFT to borrower - Now with fully qualified contract name
    (as-contract 
      (try! 
        (contract-call? 
          .nft-marketplace  ;; Replace with actual contract name
          transfer 
          (get nft-id loan) 
          contract-address
          (get borrower loan)
        )
      )
    )

    ;; Clear loan data
    (map-delete loans loan-id)
    (map-delete nft-locks 
      {
        nft-id: (get nft-id loan),
        nft-contract: (get nft-contract loan)
      }
    )
    (ok true)
  )
)