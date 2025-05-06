;; Eligibility Criteria Contract
;; Records requirements for public services

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u102))

;; Data maps
(define-map service-criteria
  { service-id: uint }
  {
    name: (string-utf8 100),
    min-age: uint,
    max-age: uint,
    income-threshold: uint,
    residency-requirement: uint,
    active: bool
  }
)

;; Track the next available service ID
(define-data-var next-service-id uint u1)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Add a new service with eligibility criteria
(define-public (add-service-criteria
    (name (string-utf8 100))
    (min-age uint)
    (max-age uint)
    (income-threshold uint)
    (residency-requirement uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)

    (let ((service-id (var-get next-service-id)))
      (map-set service-criteria
        { service-id: service-id }
        {
          name: name,
          min-age: min-age,
          max-age: max-age,
          income-threshold: income-threshold,
          residency-requirement: residency-requirement,
          active: true
        }
      )

      (var-set next-service-id (+ service-id u1))
      (ok service-id)
    )
  )
)

;; Update existing service criteria
(define-public (update-service-criteria
    (service-id uint)
    (name (string-utf8 100))
    (min-age uint)
    (max-age uint)
    (income-threshold uint)
    (residency-requirement uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (asserts! (is-some (map-get? service-criteria { service-id: service-id })) ERR-NOT-FOUND)

    (map-set service-criteria
      { service-id: service-id }
      {
        name: name,
        min-age: min-age,
        max-age: max-age,
        income-threshold: income-threshold,
        residency-requirement: residency-requirement,
        active: (get active (unwrap-panic (map-get? service-criteria { service-id: service-id })))
      }
    )
    (ok true)
  )
)

;; Activate or deactivate a service
(define-public (set-service-active (service-id uint) (active bool))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (asserts! (is-some (map-get? service-criteria { service-id: service-id })) ERR-NOT-FOUND)

    (let ((criteria (unwrap-panic (map-get? service-criteria { service-id: service-id }))))
      (map-set service-criteria
        { service-id: service-id }
        {
          name: (get name criteria),
          min-age: (get min-age criteria),
          max-age: (get max-age criteria),
          income-threshold: (get income-threshold criteria),
          residency-requirement: (get residency-requirement criteria),
          active: active
        }
      )
      (ok true)
    )
  )
)

;; Get service criteria
(define-read-only (get-service-criteria (service-id uint))
  (map-get? service-criteria { service-id: service-id })
)

;; Get total number of services
(define-read-only (get-service-count)
  (- (var-get next-service-id) u1)
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)
  )
)
