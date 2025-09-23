;; SIP-009 NFT trait implementation

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_PLAYER_EXISTS (err u402))
(define-constant ERR_PLAYER_NOT_FOUND (err u403))
(define-constant ERR_INVALID_LEVEL (err u404))
(define-constant ERR_ACHIEVEMENT_EXISTS (err u405))
(define-constant ERR_INVALID_PROOF (err u406))
(define-constant ERR_TOURNAMENT_NOT_FOUND (err u407))
(define-constant ERR_TOURNAMENT_CLOSED (err u408))
(define-constant ERR_INSUFFICIENT_XP (err u409))
(define-constant ERR_BANNED_PLAYER (err u410))
(define-constant ERR_INVALID_TOKEN (err u411))
(define-constant ERR_NOT_OWNER (err u412))

(define-constant MAX_LEVEL u100)
(define-constant XP_PER_LEVEL u1000)
(define-constant MIN_PROOF_LENGTH u32)
(define-constant MAX_TOURNAMENTS u1000)

(define-data-var contract-uri (string-utf8 256) u"https://p2e-rewards.stacks.co/metadata")
(define-data-var next-token-id uint u1)
(define-data-var next-tournament-id uint u1)

(define-map players principal {
  level: uint,
  xp: uint,
  registration-height: uint,
  session-nonce: uint,
  banned: bool,
  total-achievements: uint
})

(define-map achievements {player: principal, level: uint} {
  btc-block-height: uint,
  proof-hash: (buff 32),
  timestamp: uint,
  verified: bool
})

(define-map nft-badges uint {
  owner: principal,
  level-requirement: uint,
  achievement-type: (string-ascii 32),
  metadata-uri: (string-utf8 256)
})

(define-map tournaments uint {
  creator: principal,
  name: (string-ascii 64),
  entry-fee: uint,
  prize-pool: uint,
  max-participants: uint,
  participants: uint,
  start-height: uint,
  end-height: uint,
  closed: bool
})

(define-map tournament-participants {tournament-id: uint, player: principal} {
  score: uint,
  achievement-id: uint,
  submission-height: uint
})

(define-map tournament-rankings uint (list 100 principal))

(define-public (register-player)
  (let ((player tx-sender)
        (current-height stacks-block-height))
    (asserts! (is-none (map-get? players player)) ERR_PLAYER_EXISTS)
    (map-set players player {
      level: u1,
      xp: u0,
      registration-height: current-height,
      session-nonce: u0,
      banned: false,
      total-achievements: u0
    })
    (print {event: "player-registered", player: player, height: current-height})
    (ok true)
  )
)

(define-public (gain-xp (amount uint))
  (let ((player tx-sender)
        (player-data (unwrap! (map-get? players player) ERR_PLAYER_NOT_FOUND)))
    (asserts! (not (get banned player-data)) ERR_BANNED_PLAYER)
    (let ((new-xp (+ (get xp player-data) amount))
          (current-level (get level player-data))
          (new-level (calculate-level new-xp)))
      (map-set players player (merge player-data {
        xp: new-xp,
        level: new-level
      }))
      (if (> new-level current-level)
        (begin
          (print {event: "level-up", player: player, old-level: current-level, new-level: new-level})
          true
        )
        true
      )
      (ok new-xp)
    )
  )
)

(define-public (submit-achievement (level-req uint) (btc-block uint) (proof (buff 32)))
  (let ((player tx-sender)
        (player-data (unwrap! (map-get? players player) ERR_PLAYER_NOT_FOUND))
        (current-burn-height (unwrap! (get-burn-block-info? header-hash stacks-block-height) ERR_INVALID_PROOF)))
    (asserts! (not (get banned player-data)) ERR_BANNED_PLAYER)
    (asserts! (>= (get level player-data) level-req) ERR_INVALID_LEVEL)
    (asserts! (<= btc-block (len current-burn-height)) ERR_INVALID_PROOF)
    (asserts! (>= (len proof) MIN_PROOF_LENGTH) ERR_INVALID_PROOF)
    (asserts! (is-none (map-get? achievements {player: player, level: level-req})) ERR_ACHIEVEMENT_EXISTS)
    
    (map-set achievements {player: player, level: level-req} {
      btc-block-height: btc-block,
      proof-hash: proof,
      timestamp: stacks-block-height,
      verified: true
    })
    
    (map-set players player (merge player-data {
      total-achievements: (+ (get total-achievements player-data) u1)
    }))
    
    (unwrap-panic (mint-achievement-badge player level-req))
    (unwrap-panic (gain-xp (* level-req u100)))
    
    (print {event: "achievement-submitted", player: player, level: level-req, btc-block: btc-block})
    (ok true)
  )
)

(define-public (create-tournament (name (string-ascii 64)) (entry-fee uint) (max-participants uint) (duration uint))
  (let ((tournament-id (var-get next-tournament-id))
        (creator tx-sender)
        (start-height stacks-block-height)
        (end-height (+ start-height duration)))
    (asserts! (< tournament-id MAX_TOURNAMENTS) ERR_NOT_AUTHORIZED)
    
    (map-set tournaments tournament-id {
      creator: creator,
      name: name,
      entry-fee: entry-fee,
      prize-pool: u0,
      max-participants: max-participants,
      participants: u0,
      start-height: start-height,
      end-height: end-height,
      closed: false
    })
    
    (var-set next-tournament-id (+ tournament-id u1))
    (print {event: "tournament-created", id: tournament-id, creator: creator, name: name})
    (ok tournament-id)
  )
)

(define-public (join-tournament (tournament-id uint))
  (let ((player tx-sender)
        (tournament (unwrap! (map-get? tournaments tournament-id) ERR_TOURNAMENT_NOT_FOUND))
        (player-data (unwrap! (map-get? players player) ERR_PLAYER_NOT_FOUND)))
    (asserts! (not (get banned player-data)) ERR_BANNED_PLAYER)
    (asserts! (not (get closed tournament)) ERR_TOURNAMENT_CLOSED)
    (asserts! (< (get participants tournament) (get max-participants tournament)) ERR_NOT_AUTHORIZED)
    (asserts! (<= stacks-block-height (get end-height tournament)) ERR_TOURNAMENT_CLOSED)
    
    (if (> (get entry-fee tournament) u0)
      (try! (stx-transfer? (get entry-fee tournament) player (as-contract tx-sender)))
      true
    )
    
    (map-set tournament-participants {tournament-id: tournament-id, player: player} {
      score: u0,
      achievement-id: u0,
      submission-height: u0
    })
    
    (map-set tournaments tournament-id (merge tournament {
      participants: (+ (get participants tournament) u1),
      prize-pool: (+ (get prize-pool tournament) (get entry-fee tournament))
    }))
    
    (print {event: "tournament-joined", tournament-id: tournament-id, player: player})
    (ok true)
  )
)

(define-public (submit-tournament-score (tournament-id uint) (score uint) (achievement-level uint))
  (let ((player tx-sender)
        (tournament (unwrap! (map-get? tournaments tournament-id) ERR_TOURNAMENT_NOT_FOUND))
        (participant (unwrap! (map-get? tournament-participants {tournament-id: tournament-id, player: player}) ERR_NOT_AUTHORIZED)))
    (asserts! (not (get closed tournament)) ERR_TOURNAMENT_CLOSED)
    (asserts! (<= stacks-block-height (get end-height tournament)) ERR_TOURNAMENT_CLOSED)
    (asserts! (is-some (map-get? achievements {player: player, level: achievement-level})) ERR_PLAYER_NOT_FOUND)
    
    (map-set tournament-participants {tournament-id: tournament-id, player: player} (merge participant {
      score: score,
      achievement-id: achievement-level,
      submission-height: stacks-block-height
    }))
    
    (print {event: "score-submitted", tournament-id: tournament-id, player: player, score: score})
    (ok true)
  )
)

(define-public (close-tournament (tournament-id uint))
  (let ((tournament (unwrap! (map-get? tournaments tournament-id) ERR_TOURNAMENT_NOT_FOUND)))
    (asserts! (or (is-eq tx-sender (get creator tournament)) (is-eq tx-sender CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
    (asserts! (not (get closed tournament)) ERR_TOURNAMENT_CLOSED)
    (asserts! (>= stacks-block-height (get end-height tournament)) ERR_NOT_AUTHORIZED)
    
    (map-set tournaments tournament-id (merge tournament {closed: true}))
    (try! (distribute-prize-pool tournament-id))
    
    (print {event: "tournament-closed", tournament-id: tournament-id})
    (ok true)
  )
)

(define-public (ban-player (player principal))
  (let ((player-data (unwrap! (map-get? players player) ERR_PLAYER_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set players player (merge player-data {banned: true}))
    (print {event: "player-banned", player: player})
    (ok true)
  )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (let ((badge (unwrap! (map-get? nft-badges token-id) ERR_INVALID_TOKEN)))
    (asserts! (is-eq sender (get owner badge)) ERR_NOT_OWNER)
    (asserts! (is-eq tx-sender sender) ERR_NOT_AUTHORIZED)
    (map-set nft-badges token-id (merge badge {owner: recipient}))
    (print {event: "nft-transfer", token-id: token-id, sender: sender, recipient: recipient})
    (ok true)
  )
)

(define-read-only (get-player (player principal))
  (map-get? players player)
)

(define-read-only (get-achievement (player principal) (level uint))
  (map-get? achievements {player: player, level: level})
)

(define-read-only (get-tournament (tournament-id uint))
  (map-get? tournaments tournament-id)
)

(define-read-only (get-tournament-participant (tournament-id uint) (player principal))
  (map-get? tournament-participants {tournament-id: tournament-id, player: player})
)

(define-read-only (get-owner (token-id uint))
  (ok (get owner (unwrap! (map-get? nft-badges token-id) ERR_INVALID_TOKEN)))
)

(define-read-only (get-last-token-id)
  (ok (- (var-get next-token-id) u1))
)

(define-read-only (get-token-uri (token-id uint))
  (ok (some (get metadata-uri (unwrap! (map-get? nft-badges token-id) ERR_INVALID_TOKEN))))
)

(define-read-only (calculate-level (xp uint))
  (if (< xp XP_PER_LEVEL)
    u1
    (let ((calculated-level (+ (/ xp XP_PER_LEVEL) u1)))
      (if (> calculated-level MAX_LEVEL)
        MAX_LEVEL
        calculated-level
      )
    )
  )
)

(define-private (mint-achievement-badge (player principal) (level uint))
  (let ((token-id (var-get next-token-id))
        (badge-type (if (<= level u10) "bronze-badge" (if (<= level u25) "silver-badge" "gold-badge"))))
    (map-set nft-badges token-id {
      owner: player,
      level-requirement: level,
      achievement-type: badge-type,
      metadata-uri: u"https://p2e-rewards.co/badge"
    })
    (var-set next-token-id (+ token-id u1))
    (print {event: "badge-minted", token-id: token-id, owner: player, level: level, type: badge-type})
    (ok token-id)
  )
)

(define-private (distribute-prize-pool (tournament-id uint))
  (let ((tournament (unwrap! (map-get? tournaments tournament-id) ERR_TOURNAMENT_NOT_FOUND)))
    (if (> (get prize-pool tournament) u0)
      (as-contract (stx-transfer? (get prize-pool tournament) tx-sender (get creator tournament)))
      (ok true)
    )
  )
)
