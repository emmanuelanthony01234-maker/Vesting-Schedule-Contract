;; Vesting Schedule Contract - Automated STX release schedules for employees and investors

(define-data-var contract-owner principal tx-sender)
(define-data-var next-schedule-id uint u0)

(define-constant ERR-NOT-OWNER        (err u100))
(define-constant ERR-INVALID-PARAMS   (err u101))
(define-constant ERR-NO-SCHEDULE      (err u102))
(define-constant ERR-NOT-BENEFICIARY  (err u103))
(define-constant ERR-NOTHING-TO-CLAIM (err u104))

(define-map schedules
  { id: uint }
  {
    beneficiary: principal,
    start-burn-height: uint,
    cliff-burn-height: uint,
    duration: uint,
    total-amount: uint,
    claimed-amount: uint
  })

;; Helpers

(define-read-only (get-owner)
  (ok (var-get contract-owner)))

(define-private (is-owner (who principal))
  (is-eq who (var-get contract-owner)))

(define-private (assert-owner (who principal))
  (if (is-owner who)
      (ok true)
      ERR-NOT-OWNER))

(define-read-only (get-schedule (id uint))
  (map-get? schedules { id: id }))

(define-read-only (get-vested-amount (id uint))
  (let ((maybe-schedule (map-get? schedules { id: id })))
    (match maybe-schedule schedule
      (let ((now block-height)
            (start (get start-burn-height schedule))
            (cliff (get cliff-burn-height schedule))
            (duration (get duration schedule))
            (total (get total-amount schedule)))
        (if (< now start)
            (ok u0)
            (if (< now cliff)
                (ok u0)
                (if (is-eq duration u0)
                    (ok total)
                    (if (>= now (+ start duration))
                        (ok total)
                        (ok (/ (* total (- now start)) duration)))))))
      ERR-NO-SCHEDULE)))

(define-read-only (get-claimable-amount (id uint))
  (let ((maybe-schedule (map-get? schedules { id: id })))
    (match maybe-schedule schedule
      (let ((vested (unwrap-panic (get-vested-amount id)))
            (claimed (get claimed-amount schedule)))
        (ok (if (> vested claimed)
                (- vested claimed)
                u0)))
      ERR-NO-SCHEDULE)))

;; ADMIN FUNCTIONS

(define-public (set-owner (new-owner principal))
  (begin
    (try! (assert-owner tx-sender))
    (var-set contract-owner new-owner)
    (ok true)))

(define-public (create-schedule
    (beneficiary principal)
    (start-burn-height uint)
    (cliff-burn-height uint)
    (duration uint)
    (total-amount uint))
  (begin
    (try! (assert-owner tx-sender))
    (if (or (is-eq total-amount u0)
            (is-eq duration u0)
            (> start-burn-height cliff-burn-height))
        ERR-INVALID-PARAMS
        (let ((id (var-get next-schedule-id)))
          (var-set next-schedule-id (+ id u1))
          (map-set schedules
            { id: id }
            {
              beneficiary: beneficiary,
              start-burn-height: start-burn-height,
              cliff-burn-height: cliff-burn-height,
              duration: duration,
              total-amount: total-amount,
              claimed-amount: u0
            })
          (ok id)))))

;; BENEFICIARY FUNCTION

;; (claim (id)) will be added here to allow beneficiaries to withdraw vested amounts.

;; Read-only summary for UIs

(define-read-only (list-schedule-summary (id uint))
  (let ((maybe-schedule (map-get? schedules { id: id })))
    (match maybe-schedule schedule
      (ok {
        id: id,
        beneficiary: (get beneficiary schedule),
        start-burn-height: (get start-burn-height schedule),
        cliff-burn-height: (get cliff-burn-height schedule),
        duration: (get duration schedule),
        total-amount: (get total-amount schedule),
        claimed-amount: (get claimed-amount schedule)
      })
      ERR-NO-SCHEDULE)))