;; skill-chain.clar
;; Educational Credentials Verification Platform

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-SKILL-EXISTS (err u101))
(define-constant ERR-SKILL-NOT-FOUND (err u102))
(define-constant ERR-INVALID-INPUT (err u103))
(define-constant ERR-TRANSFER-FAILED (err u104))
(define-constant ERR-MAX-SKILLS-REACHED (err u105))

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
        revoked: bool,
        metadata: (optional (string-ascii 1000))
    }
)

;; Track total number of skills
(define-data-var total-skills uint u0)

;; Maximum number of skills to prevent potential DOS
(define-constant MAX-SKILLS u10000)

;; Events for skill-related actions
(define-trait skill-events
  (
    (skill-created (uint principal) (response bool uint))
    (skill-transferred (uint principal principal) (response bool uint))
    (skill-revoked (uint principal) (response bool uint))
  )
)

;; Create a new skill credential with optional metadata
(define-public (create-skill-credential 
    (skill-name (string-ascii 100))
    (description (string-ascii 500))
    (credential-uri (string-ascii 200))
    (metadata (optional (string-ascii 1000)))
)
    (let 
        (
            (current-total-skills (var-get total-skills))
            (skill-id (+ current-total-skills u1))
        )
        ;; Additional checks for input validation
        (asserts! (> (len skill-name) u0) ERR-INVALID-INPUT)
        (asserts! (> (len description) u0) ERR-INVALID-INPUT)
        (asserts! (> (len credential-uri) u0) ERR-INVALID-INPUT)
        
        ;; Prevent exceeding maximum skill limit
        (asserts! (< current-total-skills MAX-SKILLS) ERR-MAX-SKILLS-REACHED)
        
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
                revoked: false,
                metadata: metadata
            }
        )
        
        ;; Increment total skills
        (var-set total-skills skill-id)
        
        ;; Return the new skill ID
        (ok skill-id)
    )
)

;; Retrieve a skill credential with more robust error handling
(define-read-only (get-skill-credential 
    (skill-id uint)
    (owner principal)
)
    (match (map-get? Skills {skill-id: skill-id, owner: owner})
        skill 
            (if (get revoked skill)
                (err ERR-SKILL-NOT-FOUND)
                (ok skill)
            )
        (err ERR-SKILL-NOT-FOUND)
    )
)

;; Enhanced skill credential verification
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
        
        ;; Additional configurable verification logic
        (ok {
            is-valid: true,
            skill-name: (get name skill),
            issuer: (get issuer skill),
            verified-date: (get verified-date skill)
        })
    )
)

;; Transfer skill ownership with enhanced permissions and logging
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
            (old-owner tx-sender)
        )
        ;; Comprehensive input validation
        (asserts! (<= skill-id (var-get total-skills)) ERR-INVALID-INPUT)
        (asserts! (not (is-eq new-owner old-owner)) ERR-INVALID-INPUT)
        (asserts! (is-eq old-owner (get issuer skill)) ERR-NOT-AUTHORIZED)
        (asserts! (not (get revoked skill)) ERR-SKILL-NOT-FOUND)
        
        ;; Transfer ownership
        (map-set Skills 
            {skill-id: skill-id, owner: new-owner}
            {
                name: (get name skill),
                description: (get description skill),
                issuer: (get issuer skill),
                verified-date: (get verified-date skill),
                credential-uri: (get credential-uri skill),
                revoked: false,
                metadata: (get metadata skill)
            }
        )
        
        (ok true)
    )
)

;; Revoke a skill credential with audit trail support
(define-public (revoke-skill-credential 
    (skill-id uint)
    (revocation-reason (optional (string-ascii 500)))
)
    (let 
        (
            (skill (unwrap! 
                (map-get? Skills {skill-id: skill-id, owner: tx-sender}) 
                ERR-SKILL-NOT-FOUND
            ))
            ;; Handle metadata merging safely
            (updated-metadata 
                (if (is-some revocation-reason)
                    (some (default-to "" revocation-reason))
                    (get metadata skill)
                )
            )
        )
        (asserts! (<= skill-id (var-get total-skills)) ERR-INVALID-INPUT)
        (asserts! (is-eq tx-sender (get issuer skill)) ERR-NOT-AUTHORIZED)
        
        ;; Revoke skill with optional reason
        (map-set Skills 
            {skill-id: skill-id, owner: tx-sender}
            {
                name: (get name skill),
                description: (get description skill),
                issuer: (get issuer skill),
                verified-date: (get verified-date skill),
                credential-uri: (get credential-uri skill),
                revoked: true,
                metadata: updated-metadata
            }
        )
        
        (ok true)
    )
)

;; Get total number of skills with additional insights
(define-read-only (get-skills-overview)
    (ok {
        total-skills: (var-get total-skills),
        max-skills-allowed: MAX-SKILLS,
        remaining-capacity: (- MAX-SKILLS (var-get total-skills))
    })
)