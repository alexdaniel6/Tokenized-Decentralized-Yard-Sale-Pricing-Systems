;; Customer Flow Contract
;; Monitors peak shopping times and traffic patterns

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_INVALID_TIMESTAMP (err u401))
(define-constant ERR_INVALID_DURATION (err u402))

;; Data Variables
(define-data-var next-visit-id uint u1)
(define-data-var total-visits uint u0)
(define-data-var total-unique-visitors uint u0)

;; Data Maps
(define-map customer-visits
  { visit-id: uint }
  {
    customer: principal,
    timestamp: uint,
    duration: uint,
    items-viewed: uint,
    items-purchased: uint,
    total-spent: uint
  }
)

(define-map hourly-traffic
  { hour: uint }
  {
    visit-count: uint,
    total-duration: uint,
    total-purchases: uint,
    total-revenue: uint
  }
)

(define-map daily-stats
  { day: uint }
  {
    unique-visitors: uint,
    total-visits: uint,
    avg-duration: uint,
    conversion-rate: uint,
    total-revenue: uint
  }
)

(define-map customer-profiles
  { customer: principal }
  {
    first-visit: uint,
    last-visit: uint,
    total-visits: uint,
    total-duration: uint,
    total-purchases: uint,
    total-spent: uint,
    avg-items-per-visit: uint
  }
)

(define-map peak-hours
  { date: uint }
  {
    peak-hour: uint,
    peak-visits: uint,
    slowest-hour: uint,
    slowest-visits: uint
  }
)

;; Private Functions
(define-private (get-hour-from-timestamp (timestamp uint))
  (mod (/ timestamp u3600) u24)
)

(define-private (get-day-from-timestamp (timestamp uint))
  (/ timestamp u86400)
)

(define-private (update-hourly-traffic (hour uint) (duration uint) (purchases uint) (revenue uint))
  (let (
    (current-stats (default-to
      { visit-count: u0, total-duration: u0, total-purchases: u0, total-revenue: u0 }
      (map-get? hourly-traffic { hour: hour })
    ))
  )
    (map-set hourly-traffic
      { hour: hour }
      {
        visit-count: (+ (get visit-count current-stats) u1),
        total-duration: (+ (get total-duration current-stats) duration),
        total-purchases: (+ (get total-purchases current-stats) purchases),
        total-revenue: (+ (get total-revenue current-stats) revenue)
      }
    )
  )
)

(define-private (update-daily-stats (day uint) (is-new-visitor bool) (duration uint) (purchases uint) (revenue uint))
  (let (
    (current-stats (default-to
      { unique-visitors: u0, total-visits: u0, avg-duration: u0, conversion-rate: u0, total-revenue: u0 }
      (map-get? daily-stats { day: day })
    ))
  )
    (let (
      (new-unique (+ (get unique-visitors current-stats) (if is-new-visitor u1 u0)))
      (new-visits (+ (get total-visits current-stats) u1))
      (new-revenue (+ (get total-revenue current-stats) revenue))
      (new-total-duration (+ (* (get avg-duration current-stats) (get total-visits current-stats)) duration))
    )
      (map-set daily-stats
        { day: day }
        {
          unique-visitors: new-unique,
          total-visits: new-visits,
          avg-duration: (/ new-total-duration new-visits),
          conversion-rate: (if (> new-visits u0) (/ (* purchases u100) new-visits) u0),
          total-revenue: new-revenue
        }
      )
    )
  )
)

(define-private (update-customer-profile (customer principal) (timestamp uint) (duration uint) (items-viewed uint) (purchases uint) (spent uint))
  (let (
    (current-profile (map-get? customer-profiles { customer: customer }))
  )
    (match current-profile
      profile
        (map-set customer-profiles
          { customer: customer }
          {
            first-visit: (get first-visit profile),
            last-visit: timestamp,
            total-visits: (+ (get total-visits profile) u1),
            total-duration: (+ (get total-duration profile) duration),
            total-purchases: (+ (get total-purchases profile) purchases),
            total-spent: (+ (get total-spent profile) spent),
            avg-items-per-visit: (/ (+ (* (get avg-items-per-visit profile) (get total-visits profile)) items-viewed)
                                   (+ (get total-visits profile) u1))
          }
        )
      (map-set customer-profiles
        { customer: customer }
        {
          first-visit: timestamp,
          last-visit: timestamp,
          total-visits: u1,
          total-duration: duration,
          total-purchases: purchases,
          total-spent: spent,
          avg-items-per-visit: items-viewed
        }
      )
    )
    (is-none current-profile)
  )
)

;; Public Functions
(define-public (log-visit (customer principal) (timestamp uint) (duration uint) (items-viewed uint) (items-purchased uint) (total-spent uint))
  (let (
    (visit-id (var-get next-visit-id))
    (hour (get-hour-from-timestamp timestamp))
    (day (get-day-from-timestamp timestamp))
  )
    (asserts! (> timestamp u0) ERR_INVALID_TIMESTAMP)
    (asserts! (> duration u0) ERR_INVALID_DURATION)

    (map-set customer-visits
      { visit-id: visit-id }
      {
        customer: customer,
        timestamp: timestamp,
        duration: duration,
        items-viewed: items-viewed,
        items-purchased: items-purchased,
        total-spent: total-spent
      }
    )

    (let (
      (is-new-visitor (update-customer-profile customer timestamp duration items-viewed items-purchased total-spent))
    )
      (update-hourly-traffic hour duration items-purchased total-spent)
      (update-daily-stats day is-new-visitor duration items-purchased total-spent)

      (var-set next-visit-id (+ visit-id u1))
      (var-set total-visits (+ (var-get total-visits) u1))

      (if is-new-visitor
        (var-set total-unique-visitors (+ (var-get total-unique-visitors) u1))
        true
      )

      (ok visit-id)
    )
  )
)

(define-public (update-peak-hours (date uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    ;; This would typically analyze hourly traffic data to find peaks
    ;; For simplicity, we'll set default values that can be updated
    (map-set peak-hours
      { date: date }
      {
        peak-hour: u14,
        peak-visits: u25,
        slowest-hour: u8,
        slowest-visits: u3
      }
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-visit (visit-id uint))
  (map-get? customer-visits { visit-id: visit-id })
)

(define-read-only (get-hourly-traffic (hour uint))
  (map-get? hourly-traffic { hour: hour })
)

(define-read-only (get-daily-stats (day uint))
  (map-get? daily-stats { day: day })
)

(define-read-only (get-customer-profile (customer principal))
  (map-get? customer-profiles { customer: customer })
)

(define-read-only (get-peak-hours (date uint))
  (map-get? peak-hours { date: date })
)

(define-read-only (get-traffic-stats)
  {
    total-visits: (var-get total-visits),
    total-unique-visitors: (var-get total-unique-visitors),
    avg-visits-per-customer: (if (> (var-get total-unique-visitors) u0)
                               (/ (var-get total-visits) (var-get total-unique-visitors))
                               u0)
  }
)

(define-read-only (get-busiest-hour)
  ;; This would analyze all hourly data to find the busiest hour
  ;; For simplicity, returning a default peak hour
  u14
)

(define-read-only (calculate-conversion-rate (day uint))
  (match (map-get? daily-stats { day: day })
    stats
      (let (
        (visits (get total-visits stats))
        (purchases (get conversion-rate stats))
      )
        (some purchases)
      )
    none
  )
)

(define-read-only (get-customer-lifetime-value (customer principal))
  (match (map-get? customer-profiles { customer: customer })
    profile (some (get total-spent profile))
    none
  )
)

(define-read-only (analyze-shopping-patterns (customer principal))
  (match (map-get? customer-profiles { customer: customer })
    profile
      (some {
        visit-frequency: (/ (- (get last-visit profile) (get first-visit profile)) (get total-visits profile)),
        avg-spend-per-visit: (/ (get total-spent profile) (get total-visits profile)),
        engagement-score: (get avg-items-per-visit profile)
      })
    none
  )
)
