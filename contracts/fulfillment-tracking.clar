;; Existential Fulfillment Tracking Contract
;; Monitors progress toward deep life satisfaction and meaning

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-ASSESSMENT-NOT-FOUND (err u501))
(define-constant ERR-INVALID-INPUT (err u502))
(define-constant ERR-INVALID-RATING (err u503))
(define-constant ERR-GOAL-NOT-FOUND (err u504))

;; Data Variables
(define-data-var next-assessment-id uint u1)
(define-data-var next-goal-id uint u1)

;; Data Maps
(define-map fulfillment-assessments
  { user: principal, assessment-id: uint }
  {
    overall-satisfaction: uint,
    purpose-clarity: uint,
    meaning-richness: uint,
    value-alignment: uint,
    legacy-progress: uint,
    growth-satisfaction: uint,
    relationship-fulfillment: uint,
    contribution-impact: uint,
    assessment-date: uint,
    notes: (string-ascii 500)
  }
)

(define-map life-satisfaction-goals
  { user: principal, goal-id: uint }
  {
    goal-description: (string-ascii 200),
    target-score: uint,
    current-score: uint,
    target-date: uint,
    category: (string-ascii 50),
    progress-milestones: (list 10 uint),
    achieved: bool
  }
)

(define-map fulfillment-dimensions
  { user: principal, dimension: (string-ascii 30) }
  {
    current-rating: uint,
    target-rating: uint,
    improvement-trend: int,
    last-updated: uint,
    action-plan: (string-ascii 300)
  }
)

(define-map holistic-metrics
  { user: principal }
  {
    existential-fulfillment-score: uint,
    meaning-coherence: uint,
    life-satisfaction-trend: int,
    goal-achievement-rate: uint,
    overall-growth-trajectory: int,
    last-comprehensive-review: uint
  }
)

(define-map fulfillment-insights
  { user: principal, insight-id: uint }
  {
    insight-text: (string-ascii 400),
    insight-category: (string-ascii 50),
    actionable-steps: (string-ascii 300),
    priority-level: uint,
    created-at: uint
  }
)

;; Read-only functions
(define-read-only (get-fulfillment-assessment (user principal) (assessment-id uint))
  (map-get? fulfillment-assessments { user: user, assessment-id: assessment-id })
)

(define-read-only (get-life-goal (user principal) (goal-id uint))
  (map-get? life-satisfaction-goals { user: user, goal-id: goal-id })
)

(define-read-only (get-fulfillment-dimension (user principal) (dimension (string-ascii 30)))
  (map-get? fulfillment-dimensions { user: user, dimension: dimension })
)

(define-read-only (get-holistic-metrics (user principal))
  (map-get? holistic-metrics { user: user })
)

(define-read-only (get-fulfillment-insight (user principal) (insight-id uint))
  (map-get? fulfillment-insights { user: user, insight-id: insight-id })
)

(define-read-only (calculate-existential-score (purpose uint) (meaning uint) (values uint) (legacy uint) (growth uint) (relationships uint) (contribution uint))
  (/ (+ purpose meaning values legacy growth relationships contribution) u7)
)

;; Public functions
(define-public (record-fulfillment-assessment (overall-satisfaction uint) (purpose-clarity uint) (meaning-richness uint) (value-alignment uint) (legacy-progress uint) (growth-satisfaction uint) (relationship-fulfillment uint) (contribution-impact uint) (notes (string-ascii 500)))
  (let ((user tx-sender)
        (assessment-id (var-get next-assessment-id)))
    (asserts! (and (>= overall-satisfaction u0) (<= overall-satisfaction u100)) ERR-INVALID-RATING)
    (asserts! (and (>= purpose-clarity u0) (<= purpose-clarity u100)) ERR-INVALID-RATING)
    (asserts! (and (>= meaning-richness u0) (<= meaning-richness u100)) ERR-INVALID-RATING)
    (asserts! (and (>= value-alignment u0) (<= value-alignment u100)) ERR-INVALID-RATING)
    (asserts! (and (>= legacy-progress u0) (<= legacy-progress u100)) ERR-INVALID-RATING)
    (asserts! (and (>= growth-satisfaction u0) (<= growth-satisfaction u100)) ERR-INVALID-RATING)
    (asserts! (and (>= relationship-fulfillment u0) (<= relationship-fulfillment u100)) ERR-INVALID-RATING)
    (asserts! (and (>= contribution-impact u0) (<= contribution-impact u100)) ERR-INVALID-RATING)

    (map-set fulfillment-assessments
      { user: user, assessment-id: assessment-id }
      {
        overall-satisfaction: overall-satisfaction,
        purpose-clarity: purpose-clarity,
        meaning-richness: meaning-richness,
        value-alignment: value-alignment,
        legacy-progress: legacy-progress,
        growth-satisfaction: growth-satisfaction,
        relationship-fulfillment: relationship-fulfillment,
        contribution-impact: contribution-impact,
        assessment-date: block-height,
        notes: notes
      })

    ;; Update holistic metrics
    (update-holistic-metrics user overall-satisfaction purpose-clarity meaning-richness value-alignment legacy-progress growth-satisfaction relationship-fulfillment contribution-impact)

    (var-set next-assessment-id (+ assessment-id u1))
    (ok assessment-id))
)

(define-public (set-life-satisfaction-goal (goal-description (string-ascii 200)) (target-score uint) (target-date uint) (category (string-ascii 50)))
  (let ((user tx-sender)
        (goal-id (var-get next-goal-id)))
    (asserts! (> (len goal-description) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= target-score u0) (<= target-score u100)) ERR-INVALID-RATING)
    (asserts! (> target-date block-height) ERR-INVALID-INPUT)
    (asserts! (> (len category) u0) ERR-INVALID-INPUT)

    (map-set life-satisfaction-goals
      { user: user, goal-id: goal-id }
      {
        goal-description: goal-description,
        target-score: target-score,
        current-score: u0,
        target-date: target-date,
        category: category,
        progress-milestones: (list),
        achieved: false
      })

    (var-set next-goal-id (+ goal-id u1))
    (ok goal-id))
)

(define-public (update-goal-progress (goal-id uint) (current-score uint))
  (let ((user tx-sender)
        (goal-opt (map-get? life-satisfaction-goals { user: user, goal-id: goal-id })))
    (match goal-opt
      goal
      (begin
        (asserts! (and (>= current-score u0) (<= current-score u100)) ERR-INVALID-RATING)

        (map-set life-satisfaction-goals
          { user: user, goal-id: goal-id }
          (merge goal {
            current-score: current-score,
            achieved: (>= current-score (get target-score goal))
          }))

        (ok current-score))
      ERR-GOAL-NOT-FOUND))
)

(define-public (update-fulfillment-dimension (dimension (string-ascii 30)) (current-rating uint) (target-rating uint) (action-plan (string-ascii 300)))
  (let ((user tx-sender)
        (dimension-opt (map-get? fulfillment-dimensions { user: user, dimension: dimension })))
    (asserts! (> (len dimension) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= current-rating u0) (<= current-rating u100)) ERR-INVALID-RATING)
    (asserts! (and (>= target-rating u0) (<= target-rating u100)) ERR-INVALID-RATING)

    (match dimension-opt
      existing-dimension
      (let ((trend (- (to-int current-rating) (to-int (get current-rating existing-dimension)))))
        (map-set fulfillment-dimensions
          { user: user, dimension: dimension }
          (merge existing-dimension {
            current-rating: current-rating,
            target-rating: target-rating,
            improvement-trend: trend,
            last-updated: block-height,
            action-plan: action-plan
          })))
      ;; Create new dimension entry
      (map-set fulfillment-dimensions
        { user: user, dimension: dimension }
        {
          current-rating: current-rating,
          target-rating: target-rating,
          improvement-trend: 0,
          last-updated: block-height,
          action-plan: action-plan
        }))

    (ok current-rating))
)

(define-public (add-fulfillment-insight (insight-text (string-ascii 400)) (insight-category (string-ascii 50)) (actionable-steps (string-ascii 300)) (priority-level uint))
  (let ((user tx-sender)
        (insight-id u0)) ;; Simplified to single insight per user
    (asserts! (> (len insight-text) u0) ERR-INVALID-INPUT)
    (asserts! (> (len insight-category) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= priority-level u1) (<= priority-level u5)) ERR-INVALID-RATING)

    (map-set fulfillment-insights
      { user: user, insight-id: insight-id }
      {
        insight-text: insight-text,
        insight-category: insight-category,
        actionable-steps: actionable-steps,
        priority-level: priority-level,
        created-at: block-height
      })

    (ok insight-id))
)

(define-public (conduct-comprehensive-review)
  (let ((user tx-sender)
        (metrics-opt (map-get? holistic-metrics { user: user })))
    (match metrics-opt
      metrics
      (let ((new-coherence (+ (get meaning-coherence metrics) u5))) ;; Simplified improvement
        (map-set holistic-metrics
          { user: user }
          (merge metrics {
            meaning-coherence: (if (<= new-coherence u100) new-coherence u100),
            last-comprehensive-review: block-height
          }))
        (ok new-coherence))
      ;; Create initial metrics
      (begin
        (map-set holistic-metrics
          { user: user }
          {
            existential-fulfillment-score: u50,
            meaning-coherence: u50,
            life-satisfaction-trend: 0,
            goal-achievement-rate: u0,
            overall-growth-trajectory: 0,
            last-comprehensive-review: block-height
          })
        (ok u50))))
)

;; Private functions
(define-private (update-holistic-metrics (user principal) (overall uint) (purpose uint) (meaning uint) (values uint) (legacy uint) (growth uint) (relationships uint) (contribution uint))
  (let ((existential-score (calculate-existential-score purpose meaning values legacy growth relationships contribution))
        (metrics-opt (map-get? holistic-metrics { user: user })))
    (match metrics-opt
      metrics
      (let ((old-score (get existential-fulfillment-score metrics))
            (trend (- (to-int existential-score) (to-int old-score))))
        (map-set holistic-metrics
          { user: user }
          (merge metrics {
            existential-fulfillment-score: existential-score,
            life-satisfaction-trend: trend,
            overall-growth-trajectory: (+ (get overall-growth-trajectory metrics) trend)
          })))
      ;; Create new metrics entry
      (map-set holistic-metrics
        { user: user }
        {
          existential-fulfillment-score: existential-score,
          meaning-coherence: u50,
          life-satisfaction-trend: 0,
          goal-achievement-rate: u0,
          overall-growth-trajectory: 0,
          last-comprehensive-review: block-height
        })))
)
