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
