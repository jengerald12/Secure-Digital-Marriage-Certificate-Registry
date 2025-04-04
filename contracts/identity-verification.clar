;; Identity Verification Contract
;; This contract validates personal information of couples

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-map verified-identities
  { person-id: (string-ascii 36) }
  {
    full-name: (string-ascii 100),
    date-of-birth: (string-ascii 10),
    government-id: (string-ascii 50),
    verification-status: bool,
    verification-date: uint,
    verifier: principal
  }
)

;; Define error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_VERIFIED u2)
(define-constant ERR_NOT_FOUND u3)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Add a new identity verification
(define-public (verify-identity
    (person-id (string-ascii 36))
    (full-name (string-ascii 100))
    (date-of-birth (string-ascii 10))
    (government-id (string-ascii 50))
  )
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? verified-identities { person-id: person-id })) (err ERR_ALREADY_VERIFIED))

    (map-set verified-identities
      { person-id: person-id }
      {
        full-name: full-name,
        date-of-birth: date-of-birth,
        government-id: government-id,
        verification-status: true,
        verification-date: block-height,
        verifier: tx-sender
      }
    )
    (ok true)
  )
)

;; Get identity verification status
(define-read-only (get-verification-status (person-id (string-ascii 36)))
  (match (map-get? verified-identities { person-id: person-id })
    entry (ok entry)
    (err ERR_NOT_FOUND)
  )
)

;; Revoke identity verification
(define-public (revoke-verification (person-id (string-ascii 36)))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (match (map-get? verified-identities { person-id: person-id })
      entry (begin
        (map-set verified-identities
          { person-id: person-id }
          (merge entry { verification-status: false })
        )
        (ok true)
      )
      (err ERR_NOT_FOUND)
    )
  )
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)

