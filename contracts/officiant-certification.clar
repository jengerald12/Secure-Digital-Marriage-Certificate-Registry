;; Officiant Certification Contract
;; This contract confirms authority to perform marriages

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-map certified-officiants
  { officiant-id: principal }
  {
    full-name: (string-ascii 100),
    jurisdiction: (string-ascii 100),
    certification-number: (string-ascii 50),
    is-active: bool,
    certification-date: uint,
    expiration-date: uint
  }
)

;; Define error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_CERTIFIED u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_EXPIRED u4)
(define-constant ERR_INACTIVE u5)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Add a new officiant certification
(define-public (certify-officiant
    (officiant-id principal)
    (full-name (string-ascii 100))
    (jurisdiction (string-ascii 100))
    (certification-number (string-ascii 50))
    (expiration-date uint)
  )
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? certified-officiants { officiant-id: officiant-id })) (err ERR_ALREADY_CERTIFIED))

    (map-set certified-officiants
      { officiant-id: officiant-id }
      {
        full-name: full-name,
        jurisdiction: jurisdiction,
        certification-number: certification-number,
        is-active: true,
        certification-date: block-height,
        expiration-date: expiration-date
      }
    )
    (ok true)
  )
)

;; Check if an officiant is certified and active
(define-read-only (is-officiant-active (officiant-id principal))
  (match (map-get? certified-officiants { officiant-id: officiant-id })
    entry (and (get is-active entry) (< block-height (get expiration-date entry)))
    false
  )
)

;; Get officiant details
(define-read-only (get-officiant-details (officiant-id principal))
  (match (map-get? certified-officiants { officiant-id: officiant-id })
    entry (ok entry)
    (err ERR_NOT_FOUND)
  )
)

;; Deactivate an officiant
(define-public (deactivate-officiant (officiant-id principal))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (match (map-get? certified-officiants { officiant-id: officiant-id })
      entry (begin
        (map-set certified-officiants
          { officiant-id: officiant-id }
          (merge entry { is-active: false })
        )
        (ok true)
      )
      (err ERR_NOT_FOUND)
    )
  )
)

;; Renew an officiant's certification
(define-public (renew-officiant (officiant-id principal) (new-expiration-date uint))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (match (map-get? certified-officiants { officiant-id: officiant-id })
      entry (begin
        (map-set certified-officiants
          { officiant-id: officiant-id }
          (merge entry {
            is-active: true,
            expiration-date: new-expiration-date
          })
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

