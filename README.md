# 🎮 Decentralized Play-to-Earn Game Rewards

> Smart contract for verifiable in-game achievements tied to Bitcoin state, enabling fair reward distribution and reducing cheating in global tournaments.

## 🚀 Features

- 🏆 **Verifiable Achievements**: In-game accomplishments verified against Bitcoin blockchain state
- 🎖️ **NFT Badge System**: Earn collectible achievement badges (Bronze, Silver, Gold)
- 🏅 **Tournament Management**: Create and participate in competitive esports tournaments
- 🔒 **Anti-Cheat Protection**: Bitcoin state verification prevents manipulation
- 💰 **Fair Reward Distribution**: Transparent prize pool distribution via smart contracts
- 📊 **Level Progression**: XP-based leveling system with achievement unlocks
- 🚫 **Admin Controls**: Player management and moderation tools

## 📋 Contract Overview

The smart contract implements a comprehensive play-to-earn ecosystem with the following core components:

### Player System
- Player registration and profile management
- XP-based progression system (1000 XP per level, max level 100)
- Achievement tracking and verification
- Anti-cheat session management

### Achievement System
- Bitcoin state-tied achievement verification
- Automatic NFT badge minting for verified achievements
- Three badge tiers: Bronze (levels 1-10), Silver (levels 11-25), Gold (levels 26+)
- Proof-of-achievement with Bitcoin block height validation

### Tournament System
- Tournament creation with customizable parameters
- Entry fees and prize pool management
- Score submission with achievement verification
- Automatic prize distribution

## 🛠️ Usage Instructions

### Player Registration

```clarity
;; Register as a new player
(contract-call? .Decentralized-Play-to-Earn-Game-Rewards register-player)
```

### Gaining Experience

```clarity
;; Gain XP (typically called by game backend)
(contract-call? .Decentralized-Play-to-Earn-Game-Rewards gain-xp u500)
```

### Submitting Achievements

```clarity
;; Submit achievement with Bitcoin proof
(contract-call? .Decentralized-Play-to-Earn-Game-Rewards 
  submit-achievement 
  u5                     ;; level requirement
  u123456               ;; bitcoin block height
  0x1234...             ;; proof hash (32 bytes)
)
```

### Tournament Participation

```clarity
;; Create tournament
(contract-call? .Decentralized-Play-to-Earn-Game-Rewards 
  create-tournament 
  "Spring Championship" ;; name
  u1000000             ;; entry fee in microSTX
  u50                  ;; max participants
  u1440                ;; duration in blocks (~10 days)
)

;; Join tournament
(contract-call? .Decentralized-Play-to-Earn-Game-Rewards join-tournament u1)

;; Submit score
(contract-call? .Decentralized-Play-to-Earn-Game-Rewards 
  submit-tournament-score 
  u1     ;; tournament ID
  u9500  ;; score
  u5     ;; achievement level used
)
```

### Query Functions

```clarity
;; Get player info
(contract-call? .Decentralized-Play-to-Earn-Game-Rewards get-player 'SP1234...)

;; Get achievement
(contract-call? .Decentralized-Play-to-Earn-Game-Rewards 
  get-achievement 'SP1234... u5)

;; Get tournament details
(contract-call? .Decentralized-Play-to-Earn-Game-Rewards get-tournament u1)
```

## 🔧 Development Setup

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- Node.js and npm for testing

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/Decentralized-Play-to-Earn-Game-Rewards.git
cd Decentralized-Play-to-Earn-Game-Rewards

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test
```

### Contract Deployment

```bash
# Deploy to testnet
clarinet deployment generate --testnet
clarinet deployment apply --testnet

# Deploy to mainnet (production)
clarinet deployment generate --mainnet
clarinet deployment apply --mainnet
```

## 🏗️ Architecture

### Data Structures

**Players Map**
```clarity
{
  level: uint,
  xp: uint,
  registration-height: uint,
  session-nonce: uint,
  banned: bool,
  total-achievements: uint
}
```

**Achievements Map**
```clarity
{
  btc-block-height: uint,
  proof-hash: (buff 32),
  timestamp: uint,
  verified: bool
}
```

**NFT Badges Map**
```clarity
{
  owner: principal,
  level-requirement: uint,
  achievement-type: (string-ascii 32),
  metadata-uri: (string-utf8 256)
}
```

### Security Features

- ✅ Bitcoin state verification for achievements
- ✅ Session-based anti-cheat protection
- ✅ Admin-only player banning
- ✅ Tournament time-based validation
- ✅ Entry fee escrow system

## 🧪 Testing

Run the comprehensive test suite:

```bash
npm test
```

Test coverage includes:
- Player registration and progression
- Achievement submission and verification
- NFT badge minting
- Tournament creation and participation
- Anti-cheat mechanisms
- Error handling

## 📊 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 401 | ERR_NOT_AUTHORIZED | Caller not authorized for action |
| 402 | ERR_PLAYER_EXISTS | Player already registered |
| 403 | ERR_PLAYER_NOT_FOUND | Player not found in system |
| 404 | ERR_INVALID_LEVEL | Invalid level requirement |
| 405 | ERR_ACHIEVEMENT_EXISTS | Achievement already submitted |
| 406 | ERR_INVALID_PROOF | Invalid Bitcoin proof |
| 407 | ERR_TOURNAMENT_NOT_FOUND | Tournament does not exist |
| 408 | ERR_TOURNAMENT_CLOSED | Tournament is closed |
| 409 | ERR_INSUFFICIENT_XP | Not enough XP for action |
| 410 | ERR_BANNED_PLAYER | Player is banned |
| 411 | ERR_INVALID_TOKEN | Invalid NFT token |
| 412 | ERR_NOT_OWNER | Not the owner of resource |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/reference/language-overview)
- [Clarinet Documentation](https://docs.hiro.so/stacks/clarinet)

---

**Built with ❤️ for the decentralized gaming community**

# Decentralized Play-to-Earn Game Rewards

