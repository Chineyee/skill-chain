;; skill-chain.clar
;; Educational Credentials Verification Platform

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-SKILL-EXISTS (err u101))
(define-constant ERR-SKILL-NOT-FOUND (err u102))
(define-constant ERR-INVALID-INPUT (err u103))
(define-constant ERR-TRANSFER-FAILED (err u104))

;; Skill structure
(define-map Skills
    {
        skill-id: uint,
        owner: principal
    }
    {
        name: (string-ascii 100),
        description: (string-ascii 500),
        issuer: principal,
        verified-date: uint,
        credential-uri: (string-ascii 200),
        revoked: bool
    }
)

;; Track total number of skills
(define-data-var total-skills uint u0)

;; Events for skill-related actions
(define-trait skill-events
  (
    (skill-created (uint principal) (response bool uint))
    (skill-transferred (uint principal principal) (response bool uint))
    (skill-revoked (uint principal) (response bool uint))
  )
)

;; Create a new skill credential
(define-public (create-skill-credential 
    (skill-name (string-ascii 100))
    (description (string-ascii 500))
    (credential-uri (string-ascii 200))
)
    (let 
        (
            (skill-id (+ (var-get total-skills) u1))
        )
        (asserts! (> (len skill-name) u0) ERR-INVALID-INPUT)
        (asserts! (> (len description) u0) ERR-INVALID-INPUT)
        (asserts! (> (len credential-uri) u0) ERR-INVALID-INPUT)
        
        ;; Map the skill
        (map-set Skills 
            {
                skill-id: skill-id, 
                owner: tx-sender
            }
            {
                name: skill-name,
                description: description,
                issuer: tx-sender,
                verified-date: block-height,
                credential-uri: credential-uri,
                revoked: false
            }
        )
        
        ;; Increment total skills
        (var-set total-skills skill-id)
        
        ;; Return the new skill ID
        (ok skill-id)
    )
)

;; Retrieve a skill credential
(define-read-only (get-skill-credential 
    (skill-id uint)
    (owner principal)
)
    (match (map-get? Skills {skill-id: skill-id, owner: owner})
        skill (ok skill)
        (err ERR-SKILL-NOT-FOUND)
    )
)

;; Verify a skill credential
(define-public (verify-skill-credential 
    (skill-id uint)
    (owner principal)
)
    (let 
        (
            (skill (unwrap! 
                (map-get? Skills {skill-id: skill-id, owner: owner}) 
                ERR-SKILL-NOT-FOUND
            ))
        )
        (asserts! (not (get revoked skill)) ERR-SKILL-NOT-FOUND)
        ;; Additional verification logic can be added here
        (ok true)
    )
)

;; Transfer skill ownership (with permissions)
(define-public (transfer-skill-ownership 
    (skill-id uint)
    (new-owner principal)
)
    (let 
        (
            (skill (unwrap! 
                (map-get? Skills {skill-id: skill-id, owner: tx-sender}) 
                ERR-SKILL-NOT-FOUND
            ))
        )
        (asserts! (<= skill-id (var-get total-skills)) ERR-INVALID-INPUT)
        (asserts! (not (is-eq new-owner tx-sender)) ERR-INVALID-INPUT)
        (asserts! (is-eq tx-sender (get issuer skill)) ERR-NOT-AUTHORIZED)
        (asserts! (not (get revoked skill)) ERR-SKILL-NOT-FOUND)
        
        (map-set Skills 
            {skill-id: skill-id, owner: new-owner}
            {
                name: (get name skill),
                description: (get description skill),
                issuer: (get issuer skill),
                verified-date: (get verified-date skill),
                credential-uri: (get credential-uri skill),
                revoked: false
            }
        )
        
        (ok true)
    )
)

;; Revoke a skill credential
(define-public (revoke-skill-credential 
    (skill-id uint)
)
    (let 
        (
            (skill (unwrap! 
                (map-get? Skills {skill-id: skill-id, owner: tx-sender}) 
                ERR-SKILL-NOT-FOUND
            ))
        )
        (asserts! (<= skill-id (var-get total-skills)) ERR-INVALID-INPUT)
        (asserts! (is-eq tx-sender (get issuer skill)) ERR-NOT-AUTHORIZED)
        
        (map-set Skills 
            {skill-id: skill-id, owner: tx-sender}
            (merge skill { revoked: true })
        )
        
        (ok true)
    )
)

;; Get total number of skills
(define-read-only (get-total-skills)
    (ok (var-get total-skills))
)