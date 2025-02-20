;; Blacklist Manager Contract

;; Error Codes
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-ADDRESS-ALREADY-BLACKLISTED (err u101))
(define-constant ERR-ADDRESS-NOT-BLACKLISTED (err u102))
(define-constant ERR-INVALID-INPUT-PARAMETER (err u103))
(define-constant ERR-BULK-OPERATION-FAILED (err u104))
(define-constant ERR-ADMIN-PERMISSION-REQUIRED (err u105))
(define-constant ERR-CANNOT-BLACKLIST-ADMINISTRATOR (err u106))
(define-constant ERR-INVALID-TIMESTAMP (err u107))
(define-constant ERR-BLACKLIST-PERIOD-EXPIRED (err u108))

;; Data Variables
(define-data-var primary-contract-administrator principal tx-sender)
(define-data-var secondary-contract-administrator principal tx-sender)
(define-data-var total-blacklisted-addresses uint u0)
(define-data-var contract-operational-status bool true)
(define-data-var contract-last-modification-height uint block-height)

;; Maps
(define-map blacklist-registry principal 
  {
    is-blacklisted: bool,
    blacklist-start-time: uint,
    blacklist-end-time: uint,
    restriction-severity: uint
  })
(define-map blacklist-justifications principal (string-utf8 500))
(define-map administrator-registry principal bool)
(define-map blacklist-removal-requests principal 
  {
    request-status: (string-utf8 20),
    request-submission-time: uint,
    removal-justification: (string-utf8 500)
  })

;; Read-Only Functions
(define-read-only (check-address-blacklist-status (target-address principal))
  (match (map-get? blacklist-registry target-address)
    entry (and 
            (get is-blacklisted entry)
            (> (get blacklist-end-time entry) block-height))
    false))

(define-read-only (get-address-blacklist-information (target-address principal))
  (map-get? blacklist-registry target-address))

(define-read-only (get-blacklist-justification (target-address principal))
  (default-to u"" (map-get? blacklist-justifications target-address)))

(define-read-only (get-blacklist-total-count)
  (var-get total-blacklisted-addresses))

(define-read-only (check-administrator-status (target-address principal))
  (default-to false (map-get? administrator-registry target-address)))

(define-read-only (get-removal-request-status (target-address principal))
  (map-get? blacklist-removal-requests target-address))

(define-read-only (get-contract-details)
  {
    is-active: (var-get contract-operational-status),
    last-updated: (var-get contract-last-modification-height),
    total-blacklisted: (var-get total-blacklisted-addresses)
  })

;; Private Functions
(define-private (verify-authorization)
  (or (is-eq tx-sender (var-get primary-contract-administrator))
      (is-eq tx-sender (var-get secondary-contract-administrator))
      (check-administrator-status tx-sender)))

(define-private (calculate-blacklist-duration (duration-blocks (optional uint)))
  (default-to (+ block-height u1000) duration-blocks))

;; Public Functions
(define-public (update-primary-administrator (new-primary-admin principal))
  (begin 
    (asserts! (is-eq tx-sender (var-get primary-contract-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (is-eq new-primary-admin (var-get primary-contract-administrator))) ERR-INVALID-INPUT-PARAMETER)
    (var-set primary-contract-administrator new-primary-admin)
    (map-set administrator-registry new-primary-admin true)
    (ok true)))

(define-public (update-secondary-administrator (new-secondary-admin principal))
  (begin 
    (asserts! (is-eq tx-sender (var-get primary-contract-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (is-eq new-secondary-admin (var-get secondary-contract-administrator))) ERR-INVALID-INPUT-PARAMETER)
    (var-set secondary-contract-administrator new-secondary-admin)
    (map-set administrator-registry new-secondary-admin true)
    (ok true)))

(define-public (register-administrator (admin-address principal))
  (begin 
    (asserts! (verify-authorization) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (check-administrator-status admin-address)) ERR-ADDRESS-ALREADY-BLACKLISTED)
    (map-set administrator-registry admin-address true)
    (ok true)))

(define-public (deregister-administrator (admin-address principal))
  (begin 
    (asserts! (verify-authorization) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (is-eq admin-address (var-get primary-contract-administrator))) ERR-UNAUTHORIZED-ACCESS)
    (map-delete administrator-registry admin-address)
    (ok true)))

(define-public (add-to-blacklist 
    (target-address principal) 
    (blacklist-reason (string-utf8 500))
    (restriction-level uint)
    (duration-blocks (optional uint)))
  (begin 
    (asserts! (verify-authorization) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (check-administrator-status target-address)) ERR-CANNOT-BLACKLIST-ADMINISTRATOR)
    (asserts! (not (check-address-blacklist-status target-address)) ERR-ADDRESS-ALREADY-BLACKLISTED)
    (asserts! (> (len blacklist-reason) u0) ERR-INVALID-INPUT-PARAMETER)
    (asserts! (and (>= restriction-level u1) (<= restriction-level u10)) ERR-INVALID-INPUT-PARAMETER)
    (let ((calculated-end-time (calculate-blacklist-duration duration-blocks)))
      (asserts! (> calculated-end-time block-height) ERR-INVALID-TIMESTAMP)
      (map-set blacklist-registry target-address 
        {
          is-blacklisted: true,
          blacklist-start-time: block-height,
          blacklist-end-time: calculated-end-time,
          restriction-severity: restriction-level
        })
      (map-set blacklist-justifications target-address blacklist-reason)
      (var-set total-blacklisted-addresses (+ (var-get total-blacklisted-addresses) u1))
      (var-set contract-last-modification-height block-height)
      (ok true))))

(define-public (remove-from-blacklist (target-address principal))
  (begin 
    (asserts! (verify-authorization) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (check-address-blacklist-status target-address) ERR-ADDRESS-NOT-BLACKLISTED)
    (map-delete blacklist-registry target-address)
    (map-delete blacklist-justifications target-address)
    (var-set total-blacklisted-addresses (- (var-get total-blacklisted-addresses) u1))
    (var-set contract-last-modification-height block-height)
    (ok true)))

(define-public (submit-removal-request (removal-reason (string-utf8 500)))
  (begin
    (asserts! (check-address-blacklist-status tx-sender) ERR-ADDRESS-NOT-BLACKLISTED)
    (asserts! (> (len removal-reason) u0) ERR-INVALID-INPUT-PARAMETER)
    (map-set blacklist-removal-requests tx-sender
      {
        request-status: u"pending",
        request-submission-time: block-height,
        removal-justification: removal-reason
      })
    (ok true)))

(define-public (review-removal-request (target-address principal) (request-approved bool))
  (begin
    (asserts! (verify-authorization) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (check-address-blacklist-status target-address) ERR-ADDRESS-NOT-BLACKLISTED)
    (let ((request-data (unwrap! (map-get? blacklist-removal-requests target-address) ERR-ADDRESS-NOT-BLACKLISTED)))
      (map-set blacklist-removal-requests target-address
        (merge request-data { request-status: (if request-approved u"approved" u"rejected") }))
      (if request-approved 
        (remove-from-blacklist target-address)
        (ok true)))))

(define-public (toggle-contract-operations)
  (begin
    (asserts! (verify-authorization) ERR-UNAUTHORIZED-ACCESS)
    (var-set contract-operational-status (not (var-get contract-operational-status)))
    (ok true)))

(define-public (update-blacklist-duration (target-address principal) (new-end-time uint))
  (begin
    (asserts! (verify-authorization) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> new-end-time block-height) ERR-INVALID-TIMESTAMP)
    (asserts! (check-address-blacklist-status target-address) ERR-ADDRESS-NOT-BLACKLISTED)
    (match (map-get? blacklist-registry target-address)
      entry (begin
              (map-set blacklist-registry target-address
                (merge entry { blacklist-end-time: new-end-time }))
              (ok true))
      ERR-ADDRESS-NOT-BLACKLISTED)))

;; Prevent STX transfer to the contract
(define-public (receive-stx)
  (err ERR-INVALID-INPUT-PARAMETER))