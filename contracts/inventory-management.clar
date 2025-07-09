;; Inventory Management Contract
;; Tracks sold and remaining merchandise

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_ITEM_NOT_FOUND (err u301))
(define-constant ERR_ITEM_ALREADY_SOLD (err u302))
(define-constant ERR_INVALID_QUANTITY (err u303))
(define-constant ERR_INSUFFICIENT_STOCK (err u304))

;; Data Variables
(define-data-var next-inventory-id uint u1)
(define-data-var total-items uint u0)
(define-data-var total-sold uint u0)
(define-data-var total-revenue uint u0)

;; Data Maps
(define-map inventory
  { inventory-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 200),
    category: (string-ascii 50),
    quantity: uint,
    price: uint,
    cost: uint,
    status: (string-ascii 20),
    owner: principal,
    created-at: uint,
    updated-at: uint
  }
)

(define-map sales-records
  { sale-id: uint }
  {
    inventory-id: uint,
    buyer: principal,
    quantity: uint,
    sale-price: uint,
    timestamp: uint,
    payment-method: (string-ascii 50)
  }
)

(define-map category-stats
  { category: (string-ascii 50) }
  {
    total-items: uint,
    sold-items: uint,
    total-revenue: uint,
    avg-price: uint
  }
)

(define-map owner-inventory
  { owner: principal, inventory-id: uint }
  { active: bool }
)

;; Data Variables for sales
(define-data-var next-sale-id uint u1)

;; Private Functions
(define-private (update-category-stats (category (string-ascii 50)) (quantity uint) (revenue uint) (sold bool))
  (let (
    (current-stats (default-to
      { total-items: u0, sold-items: u0, total-revenue: u0, avg-price: u0 }
      (map-get? category-stats { category: category })
    ))
  )
    (let (
      (new-total-items (+ (get total-items current-stats) quantity))
      (new-sold-items (+ (get sold-items current-stats) (if sold quantity u0)))
      (new-total-revenue (+ (get total-revenue current-stats) revenue))
    )
      (map-set category-stats
        { category: category }
        {
          total-items: new-total-items,
          sold-items: new-sold-items,
          total-revenue: new-total-revenue,
          avg-price: (if (> new-sold-items u0) (/ new-total-revenue new-sold-items) u0)
        }
      )
    )
  )
)

;; Public Functions
(define-public (add-inventory-item (name (string-ascii 100)) (description (string-ascii 200)) (category (string-ascii 50)) (quantity uint) (price uint) (cost uint))
  (let (
    (inventory-id (var-get next-inventory-id))
  )
    (asserts! (> quantity u0) ERR_INVALID_QUANTITY)
    (asserts! (> price u0) (err u305))

    (map-set inventory
      { inventory-id: inventory-id }
      {
        name: name,
        description: description,
        category: category,
        quantity: quantity,
        price: price,
        cost: cost,
        status: "available",
        owner: tx-sender,
        created-at: block-height,
        updated-at: block-height
      }
    )

    (map-set owner-inventory
      { owner: tx-sender, inventory-id: inventory-id }
      { active: true }
    )

    (update-category-stats category quantity u0 false)

    (var-set next-inventory-id (+ inventory-id u1))
    (var-set total-items (+ (var-get total-items) quantity))

    (ok inventory-id)
  )
)

(define-public (update-inventory-item (inventory-id uint) (quantity uint) (price uint))
  (let (
    (item (unwrap! (map-get? inventory { inventory-id: inventory-id }) ERR_ITEM_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq (get status item) "sold")) ERR_ITEM_ALREADY_SOLD)

    (map-set inventory
      { inventory-id: inventory-id }
      (merge item {
        quantity: quantity,
        price: price,
        updated-at: block-height
      })
    )

    (ok true)
  )
)

(define-public (record-sale (inventory-id uint) (buyer principal) (quantity uint) (sale-price uint) (payment-method (string-ascii 50)))
  (let (
    (item (unwrap! (map-get? inventory { inventory-id: inventory-id }) ERR_ITEM_NOT_FOUND))
    (sale-id (var-get next-sale-id))
  )
    (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)
    (asserts! (>= (get quantity item) quantity) ERR_INSUFFICIENT_STOCK)
    (asserts! (> quantity u0) ERR_INVALID_QUANTITY)

    (let (
      (new-quantity (- (get quantity item) quantity))
      (new-status (if (is-eq new-quantity u0) "sold" "available"))
    )
      (map-set inventory
        { inventory-id: inventory-id }
        (merge item {
          quantity: new-quantity,
          status: new-status,
          updated-at: block-height
        })
      )

      (map-set sales-records
        { sale-id: sale-id }
        {
          inventory-id: inventory-id,
          buyer: buyer,
          quantity: quantity,
          sale-price: sale-price,
          timestamp: block-height,
          payment-method: payment-method
        }
      )

      (update-category-stats (get category item) u0 (* quantity sale-price) true)

      (var-set next-sale-id (+ sale-id u1))
      (var-set total-sold (+ (var-get total-sold) quantity))
      (var-set total-revenue (+ (var-get total-revenue) (* quantity sale-price)))

      (ok sale-id)
    )
  )
)

(define-public (mark-as-donated (inventory-id uint))
  (let (
    (item (unwrap! (map-get? inventory { inventory-id: inventory-id }) ERR_ITEM_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq (get status item) "sold")) ERR_ITEM_ALREADY_SOLD)

    (map-set inventory
      { inventory-id: inventory-id }
      (merge item {
        status: "donated",
        updated-at: block-height
      })
    )

    (ok true)
  )
)

(define-public (update-item-status (inventory-id uint) (new-status (string-ascii 20)))
  (let (
    (item (unwrap! (map-get? inventory { inventory-id: inventory-id }) ERR_ITEM_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)

    (map-set inventory
      { inventory-id: inventory-id }
      (merge item {
        status: new-status,
        updated-at: block-height
      })
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-inventory-item (inventory-id uint))
  (map-get? inventory { inventory-id: inventory-id })
)

(define-read-only (get-sale-record (sale-id uint))
  (map-get? sales-records { sale-id: sale-id })
)

(define-read-only (get-category-stats (category (string-ascii 50)))
  (map-get? category-stats { category: category })
)

(define-read-only (get-inventory-stats)
  {
    total-items: (var-get total-items),
    total-sold: (var-get total-sold),
    total-revenue: (var-get total-revenue),
    remaining-items: (- (var-get total-items) (var-get total-sold))
  }
)

(define-read-only (is-owner-item (owner principal) (inventory-id uint))
  (default-to false (get active (map-get? owner-inventory { owner: owner, inventory-id: inventory-id })))
)

(define-read-only (get-item-profit (inventory-id uint))
  (match (map-get? inventory { inventory-id: inventory-id })
    item (some (- (get price item) (get cost item)))
    none
  )
)

(define-read-only (calculate-turnover-rate (category (string-ascii 50)))
  (match (map-get? category-stats { category: category })
    stats
      (let (
        (total (get total-items stats))
        (sold (get sold-items stats))
      )
        (if (> total u0)
          (some (/ (* sold u100) total))
          (some u0)
        )
      )
    none
  )
)
