(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-FARMER-NOT-FOUND (err u2))
(define-constant ERR-BATCH-NOT-FOUND (err u3))
(define-constant ERR-ALREADY-REGISTERED (err u4))
(define-constant ERR-INVALID-QR-CODE (err u5))
(define-constant ERR-BATCH-ALREADY-EXISTS (err u6))
(define-constant ERR-INVALID-STAGE (err u7))
(define-constant ERR-NOT-OWNER (err u8))
(define-constant ERR-TRANSFER-TO-SELF (err u9))
(define-constant ERR-ISSUE-NOT-FOUND (err u10))

(define-data-var next-farmer-id uint u1)
(define-data-var next-batch-id uint u1)
(define-data-var incentive-pool uint u0)
(define-data-var next-transfer-id uint u1)
(define-data-var next-issue-id uint u1)

(define-map farmers
  { farmer-id: uint }
  {
    principal: principal,
    name: (string-ascii 50),
    location: (string-ascii 100),
    certified-sustainable: bool,
    registration-block: uint,
    total-batches: uint,
    sustainability-score: uint
  }
)

(define-map farmer-principals
  { principal: principal }
  { farmer-id: uint }
)

(define-map rice-batches
  { batch-id: uint }
  {
    farmer-id: uint,
    qr-code: (string-ascii 32),
    variety: (string-ascii 30),
    quantity-kg: uint,
    harvest-date: uint,
    processing-date: (optional uint),
    transport-date: (optional uint),
    market-date: (optional uint),
    current-stage: (string-ascii 20),
    quality-score: uint,
    sustainable-certified: bool,
    current-owner: principal
  }
)

(define-map batch-tracking
  { batch-id: uint, stage: (string-ascii 20) }
  {
    timestamp: uint,
    handler: principal,
    location: (string-ascii 100),
    temperature: (optional uint),
    humidity: (optional uint),
    notes: (string-ascii 200)
  }
)

(define-map qr-code-to-batch
  { qr-code: (string-ascii 32) }
  { batch-id: uint }
)

(define-map ownership-transfers
  { transfer-id: uint }
  {
    batch-id: uint,
    from-owner: principal,
    to-owner: principal,
    transfer-timestamp: uint,
    transfer-reason: (string-ascii 100)
  }
)

(define-map quality-issues
  { issue-id: uint }
  {
    batch-id: uint,
    reporter: principal,
    issue-type: (string-ascii 50),
    description: (string-ascii 200),
    severity: uint,
    reported-at: uint,
    resolved: bool,
    resolution-notes: (optional (string-ascii 200))
  }
)

(define-public (register-farmer (name (string-ascii 50)) (location (string-ascii 100)) (certified-sustainable bool))
  (let 
    (
      (farmer-id (var-get next-farmer-id))
      (existing-farmer (map-get? farmer-principals { principal: tx-sender }))
    )
    (asserts! (is-none existing-farmer) ERR-ALREADY-REGISTERED)
    (map-set farmers
      { farmer-id: farmer-id }
      {
        principal: tx-sender,
        name: name,
        location: location,
        certified-sustainable: certified-sustainable,
        registration-block: stacks-block-height,
        total-batches: u0,
        sustainability-score: (if certified-sustainable u100 u0)
      }
    )
    (map-set farmer-principals
      { principal: tx-sender }
      { farmer-id: farmer-id }
    )
    (var-set next-farmer-id (+ farmer-id u1))
    (ok farmer-id)
  )
)

(define-public (create-rice-batch 
  (qr-code (string-ascii 32))
  (variety (string-ascii 30))
  (quantity-kg uint)
  (harvest-date uint)
  (quality-score uint)
)
  (let 
    (
      (farmer-data (map-get? farmer-principals { principal: tx-sender }))
      (batch-id (var-get next-batch-id))
      (existing-qr (map-get? qr-code-to-batch { qr-code: qr-code }))
    )
    (asserts! (is-some farmer-data) ERR-FARMER-NOT-FOUND)
    (asserts! (is-none existing-qr) ERR-BATCH-ALREADY-EXISTS)
    (let 
      (
        (farmer-id (get farmer-id (unwrap-panic farmer-data)))
        (farmer-info (unwrap-panic (map-get? farmers { farmer-id: farmer-id })))
        (is-sustainable (get certified-sustainable farmer-info))
      )
      (map-set rice-batches
        { batch-id: batch-id }
        {
          farmer-id: farmer-id,
          qr-code: qr-code,
          variety: variety,
          quantity-kg: quantity-kg,
          harvest-date: harvest-date,
          processing-date: none,
          transport-date: none,
          market-date: none,
          current-stage: "harvested",
          quality-score: quality-score,
          sustainable-certified: is-sustainable,
          current-owner: tx-sender
        }
      )
      (map-set qr-code-to-batch
        { qr-code: qr-code }
        { batch-id: batch-id }
      )
      (map-set batch-tracking
        { batch-id: batch-id, stage: "harvested" }
        {
          timestamp: harvest-date,
          handler: tx-sender,
          location: (get location farmer-info),
          temperature: none,
          humidity: none,
          notes: "Rice harvested from farm"
        }
      )
      (map-set farmers
        { farmer-id: farmer-id }
        (merge farmer-info { total-batches: (+ (get total-batches farmer-info) u1) })
      )
      (var-set next-batch-id (+ batch-id u1))
      (ok batch-id)
    )
  )
)

(define-public (update-batch-stage 
  (batch-id uint)
  (new-stage (string-ascii 20))
  (location (string-ascii 100))
  (temperature (optional uint))
  (humidity (optional uint))
  (notes (string-ascii 200))
)
  (let 
    (
      (batch-data (map-get? rice-batches { batch-id: batch-id }))
    )
    (asserts! (is-some batch-data) ERR-BATCH-NOT-FOUND)
    (let 
      (
        (batch-info (unwrap-panic batch-data))
        (current-stage (get current-stage batch-info))
        (current-owner (get current-owner batch-info))
        (timestamp stacks-block-height)
      )
      (asserts! (is-eq tx-sender current-owner) ERR-NOT-OWNER)
      (asserts! (not (is-eq current-stage new-stage)) ERR-INVALID-STAGE)
      (map-set rice-batches
        { batch-id: batch-id }
        (merge batch-info {
          current-stage: new-stage,
          processing-date: (if (is-eq new-stage "processed") (some timestamp) (get processing-date batch-info)),
          transport-date: (if (is-eq new-stage "in-transit") (some timestamp) (get transport-date batch-info)),
          market-date: (if (is-eq new-stage "at-market") (some timestamp) (get market-date batch-info)),
          current-owner: tx-sender
        })
      )
      (map-set batch-tracking
        { batch-id: batch-id, stage: new-stage }
        {
          timestamp: timestamp,
          handler: tx-sender,
          location: location,
          temperature: temperature,
          humidity: humidity,
          notes: notes
        }
      )
      (ok true)
    )
  )
)

(define-public (verify-qr-code (qr-code (string-ascii 32)))
  (let 
    (
      (batch-mapping (map-get? qr-code-to-batch { qr-code: qr-code }))
    )
    (asserts! (is-some batch-mapping) ERR-INVALID-QR-CODE)
    (let 
      (
        (batch-id (get batch-id (unwrap-panic batch-mapping)))
        (batch-data (unwrap-panic (map-get? rice-batches { batch-id: batch-id })))
        (farmer-data (unwrap-panic (map-get? farmers { farmer-id: (get farmer-id batch-data) })))
      )
      (ok {
        batch-id: batch-id,
        farmer-name: (get name farmer-data),
        farmer-location: (get location farmer-data),
        variety: (get variety batch-data),
        quantity-kg: (get quantity-kg batch-data),
        harvest-date: (get harvest-date batch-data),
        current-stage: (get current-stage batch-data),
        quality-score: (get quality-score batch-data),
        sustainable-certified: (get sustainable-certified batch-data),
        sustainability-score: (get sustainability-score farmer-data)
      })
    )
  )
)

(define-public (award-sustainability-incentive (farmer-id uint) (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (let 
      (
        (farmer-data (map-get? farmers { farmer-id: farmer-id }))
      )
      (asserts! (is-some farmer-data) ERR-FARMER-NOT-FOUND)
      (let 
        (
          (farmer-info (unwrap-panic farmer-data))
          (new-score (+ (get sustainability-score farmer-info) amount))
        )
        (map-set farmers
          { farmer-id: farmer-id }
          (merge farmer-info { sustainability-score: new-score })
        )
        (var-set incentive-pool (+ (var-get incentive-pool) amount))
        (ok new-score)
      )
    )
  )
)

(define-public (certify-sustainable-farming (farmer-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (let 
      (
        (farmer-data (map-get? farmers { farmer-id: farmer-id }))
      )
      (asserts! (is-some farmer-data) ERR-FARMER-NOT-FOUND)
      (let 
        (
          (farmer-info (unwrap-panic farmer-data))
        )
        (map-set farmers
          { farmer-id: farmer-id }
          (merge farmer-info { certified-sustainable: true, sustainability-score: u100 })
        )
        (ok true)
      )
    )
  )
)

(define-public (transfer-batch-ownership (batch-id uint) (new-owner principal) (transfer-reason (string-ascii 100)))
  (let 
    (
      (batch-data (map-get? rice-batches { batch-id: batch-id }))
      (transfer-id (var-get next-transfer-id))
    )
    (asserts! (is-some batch-data) ERR-BATCH-NOT-FOUND)
    (let 
      (
        (batch-info (unwrap-panic batch-data))
        (current-owner (get current-owner batch-info))
      )
      (asserts! (is-eq tx-sender current-owner) ERR-NOT-OWNER)
      (asserts! (not (is-eq tx-sender new-owner)) ERR-TRANSFER-TO-SELF)
      (map-set rice-batches
        { batch-id: batch-id }
        (merge batch-info { current-owner: new-owner })
      )
      (map-set ownership-transfers
        { transfer-id: transfer-id }
        {
          batch-id: batch-id,
          from-owner: current-owner,
          to-owner: new-owner,
          transfer-timestamp: stacks-block-height,
          transfer-reason: transfer-reason
        }
      )
      (var-set next-transfer-id (+ transfer-id u1))
      (ok transfer-id)
    )
  )
)

(define-read-only (get-farmer (farmer-id uint))
  (map-get? farmers { farmer-id: farmer-id })
)

(define-read-only (get-farmer-by-principal (principal principal))
  (match (map-get? farmer-principals { principal: principal })
    farmer-mapping (map-get? farmers { farmer-id: (get farmer-id farmer-mapping) })
    none
  )
)

(define-read-only (get-batch (batch-id uint))
  (map-get? rice-batches { batch-id: batch-id })
)

(define-read-only (get-batch-tracking (batch-id uint) (stage (string-ascii 20)))
  (map-get? batch-tracking { batch-id: batch-id, stage: stage })
)

(define-read-only (get-total-farmers)
  (- (var-get next-farmer-id) u1)
)

(define-read-only (get-total-batches)
  (- (var-get next-batch-id) u1)
)

(define-read-only (get-incentive-pool)
  (var-get incentive-pool)
)

(define-read-only (get-ownership-transfer (transfer-id uint))
  (map-get? ownership-transfers { transfer-id: transfer-id })
)

(define-read-only (get-batch-owner (batch-id uint))
  (match (map-get? rice-batches { batch-id: batch-id })
    batch-data (some (get current-owner batch-data))
    none
  )
)

(define-public (report-quality-issue (batch-id uint) (issue-type (string-ascii 50)) (description (string-ascii 200)) (severity uint))
  (let
    (
      (batch-data (map-get? rice-batches { batch-id: batch-id }))
      (issue-id (var-get next-issue-id))
    )
    (asserts! (is-some batch-data) ERR-BATCH-NOT-FOUND)
    (asserts! (> severity u0) ERR-INVALID-STAGE)
    (asserts! (<= severity u10) ERR-INVALID-STAGE)
    (map-set quality-issues
      { issue-id: issue-id }
      {
        batch-id: batch-id,
        reporter: tx-sender,
        issue-type: issue-type,
        description: description,
        severity: severity,
        reported-at: stacks-block-height,
        resolved: false,
        resolution-notes: none
      }
    )
    (var-set next-issue-id (+ issue-id u1))
    (ok issue-id)
  )
)

(define-public (resolve-quality-issue (issue-id uint) (resolution-notes (string-ascii 200)))
  (let
    (
      (issue-data (map-get? quality-issues { issue-id: issue-id }))
    )
    (asserts! (is-some issue-data) ERR-ISSUE-NOT-FOUND)
    (let
      (
        (issue-info (unwrap-panic issue-data))
        (batch-data (unwrap-panic (map-get? rice-batches { batch-id: (get batch-id issue-info) })))
      )
      (asserts! (is-eq tx-sender (get current-owner batch-data)) ERR-NOT-OWNER)
      (map-set quality-issues
        { issue-id: issue-id }
        (merge issue-info { resolved: true, resolution-notes: (some resolution-notes) })
      )
      (ok true)
    )
  )
)

(define-read-only (get-quality-issue (issue-id uint))
  (map-get? quality-issues { issue-id: issue-id })
)

(define-read-only (get-batch-issues (batch-id uint))
  (let
    (
      (issues (list))
    )
    (ok issues)
  )
)
