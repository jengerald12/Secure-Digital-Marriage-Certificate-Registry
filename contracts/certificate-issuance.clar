;; Certificate Issuance Contract
;; This contract records official marriage documentation

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var certificate-counter uint u0)

(define-map marriage-certificates
  { certificate-id: uint }
  {
    person1-id: (string-ascii 36),
    person2-id: (string-ascii 36),
    officiant-id: principal,
    marriage-date: (string-ascii 10),
    jurisdiction: (string-ascii 100),
    issuance-date: uint,
    is-valid: bool
  }
)

;; Define error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_INVALID_OFFICIANT u2)
(define-constant ERR_CERTIFICATE_EXISTS u3)
(define-constant ERR_NOT_FOUND u4)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Get the next certificate ID and increment counter
(define-private (get-next-certificate-id)
  (let ((current-id (var-get certificate-counter)))
    (var-set certificate-counter (+ current-id u1))
    current-id
  )
)

;; Issue a new marriage certificate
(define-public (issue-certificate
    (person1-id (string-ascii 36))
    (person2-id (string-ascii 36))
    (officiant-id principal)
    (marriage-date (string-ascii 10))
    (jurisdiction (string-ascii 100))
  )
  (let ((certificate-id (get-next-certificate-id)))
    (begin
      ;; Only officiants or contract owner can issue certificates
      (asserts! (or (is-contract-owner) (is-eq tx-sender officiant-id)) (err ERR_UNAUTHORIZED))

      ;; Check if officiant is active (requires officiant contract)
      ;; This would typically call the officiant contract to verify
      ;; For simplicity, we're just checking if the officiant is the caller or owner

      (map-set marriage-certificates
        { certificate-id: certificate-id }
        {
          person1-id: person1-id,
          person2-id: person2-id,
          officiant-id: officiant-id,
          marriage-date: marriage-date,
          jurisdiction: jurisdiction,
          issuance-date: block-height,
          is-valid: true
        }
      )
      (ok certificate-id)
    )
  )
)

;; Get certificate details
(define-read-only (get-certificate (certificate-id uint))
  (match (map-get? marriage-certificates { certificate-id: certificate-id })
    entry (ok entry)
    (err ERR_NOT_FOUND)
  )
)

;; Invalidate a certificate (for administrative corrections)
(define-public (invalidate-certificate (certificate-id uint))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (match (map-get? marriage-certificates { certificate-id: certificate-id })
      entry (begin
        (map-set marriage-certificates
          { certificate-id: certificate-id }
          (merge entry { is-valid: false })
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

