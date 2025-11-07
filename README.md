A blockchain-based solution for tracking rice from farm to market, ensuring transparency and authenticity in the rice supply chain.

## 🎯 Overview

This smart contract enables farmers, processors, distributors, and consumers to track rice through every stage of the supply chain. Each batch of rice gets a unique QR code that consumers can scan to verify origin, quality, and sustainability.

## ✨ Key Features

- 👨‍🌾 **Farmer Registration**: Digital IDs for verified farmers
- 📦 **Batch Tracking**: Complete journey from harvest to market
- 🔍 **QR Code Verification**: Instant authenticity checks for consumers
- 🌱 **Sustainability Incentives**: Rewards for sustainable farming practices
- 📊 **Quality Scoring**: Transparent quality metrics
- 🏆 **Certification System**: Verified sustainable farming badges
- 🚨 **Quality Issue Reporting**: Track and resolve quality concerns in real-time
- 🏅 **Third-Party Certification**: Independent certifiers validate batch quality and standards

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- [Node.js](https://nodejs.org/) for testing

### Installation

```bash
git clone <repository-url>
cd Rice-Supply-Chain-Transparency-System
clarinet check
npm install
npm test
```

## 📋 Usage Instructions

### 1. Register as a Farmer 👨‍🌾

```clarity
(contract-call? .rice-supply-chain register-farmer 
  "John Smith Farm" 
  "Bohol, Philippines" 
  true)  ;; certified sustainable
```

### 2. Create Rice Batch 📦

```clarity
(contract-call? .rice-supply-chain create-rice-batch
  "QR123456789012345678901234567890"  ;; unique QR code
  "Jasmine Rice"                       ;; variety
  u1000                               ;; quantity in kg
  u1640995200                         ;; harvest date timestamp
  u95)                                ;; quality score (0-100)
```

### 3. Update Batch Stage 🚚

```clarity
(contract-call? .rice-supply-chain update-batch-stage
  u1                                  ;; batch ID
  "processed"                         ;; new stage
  "Rice Mill, Cebu"                   ;; location
  (some u25)                          ;; temperature °C
  (some u60)                          ;; humidity %
  "Rice milled and packaged")         ;; notes
```

### 4. Verify QR Code 🔍

```clarity
(contract-call? .rice-supply-chain verify-qr-code
  "QR123456789012345678901234567890")
```

### 5. Award Sustainability Incentives 🌱

```clarity
(contract-call? .rice-supply-chain award-sustainability-incentive
  u1    ;; farmer ID
  u50)  ;; incentive points
```

### 6. Report Quality Issue 🚨

```clarity
(contract-call? .rice-supply-chain report-quality-issue
  u1                                  ;; batch ID
  "contamination"                     ;; issue type
  "Foreign particles detected"        ;; description
  u8)                                 ;; severity (1-10)
```

### 7. Resolve Quality Issue ✅

```clarity
(contract-call? .rice-supply-chain resolve-quality-issue
  u1                                  ;; issue ID
  "Issue resolved after inspection")  ;; resolution notes
```

### 8. Register as a Certifier 🏅

```clarity
(contract-call? .rice-supply-chain register-certifier
  "Global Food Standards Inc."        ;; certifier name
  "International Certification Body"  ;; organization
  "Organic & Sustainable")            ;; certification type
```

### 9. Certify Rice Batch 🏅

```clarity
(contract-call? .rice-supply-chain certify-batch
  u1                                  ;; batch ID
  "Organic Certified"                 ;; certification type
  u1672531200                         ;; expiry date timestamp
  u95                                 ;; certification score (0-100)
  "Certified organic by independent auditor")  ;; notes
```

## 📊 Data Structures

### Farmer Profile
- 🆔 Unique farmer ID
- 👤 Principal address
- 📍 Farm location
- ✅ Sustainability certification
- 📈 Total batches produced
- 🏆 Sustainability score

### Rice Batch
- 🔢 Unique batch ID
- 🏷️ QR code identifier
- 🌾 Rice variety
- ⚖️ Quantity in kilograms
- 📅 Harvest/processing/transport dates
- 📍 Current stage and owner
- ⭐ Quality and sustainability scores

### Certifier Profile
- 🆔 Unique certifier ID
- 👤 Principal address
- 🏢 Organization name
- 🏅 Certification type (e.g., Organic, Fair Trade)
- 📈 Total certifications issued
- 📅 Registration block

### Batch Certification
- 🔢 Batch ID
- 🆔 Certifier ID
- 🏅 Certification type
- 📅 Certification and expiry dates
- ⭐ Certification score
- 📝 Certification notes

### Supply Chain Stages
- 🌾 **Harvested**: Fresh from farm
- 🏭 **Processed**: Milled and packaged
- 🚛 **In-Transit**: Moving to market
- 🏪 **At-Market**: Available to consumers

## 🔧 Available Functions

### Public Functions
- `register-farmer` - Register new farmer
- `create-rice-batch` - Create new rice batch
- `update-batch-stage` - Update supply chain stage
- `verify-qr-code` - Verify batch authenticity
- `award-sustainability-incentive` - Award farmer incentives
- `certify-sustainable-farming` - Grant sustainability certification
- `report-quality-issue` - Report quality concerns for batches
- `resolve-quality-issue` - Resolve reported quality issues
- `register-certifier` - Register independent certification authority
- `certify-batch` - Issue third-party certification for rice batches

### Read-Only Functions
- `get-farmer` - Get farmer details by ID
- `get-farmer-by-principal` - Get farmer by wallet address
- `get-batch` - Get batch details
- `get-batch-tracking` - Get stage tracking info
- `get-total-farmers` - Total registered farmers
- `get-total-batches` - Total rice batches
- `get-incentive-pool` - Total incentives awarded
- `get-quality-issue` - Get details of a specific quality issue
- `get-batch-issues` - Get all issues for a batch
- `get-certifier` - Get certifier details by ID
- `get-certifier-by-principal` - Get certifier by wallet address
- `get-batch-certification` - Get certification details for a batch
- `get-total-certifiers` - Total registered certifiers

## 🧪 Testing

Run the test suite:

```bash
npm test
```

## 🛡️ Security Features

- ✅ Validated input parameters
- 🔒 Access control for admin functions
- 🚫 Duplicate prevention (farmers, QR codes)
- 💪 Error handling with descriptive codes
- 🔍 Immutable supply chain records

## 📝 Error Codes

- `u1` - Not authorized
- `u2` - Farmer not found
- `u3` - Batch not found
- `u4` - Already registered
- `u5` - Invalid QR code
- `u6` - Batch already exists
- `u7` - Invalid stage transition
- `u10` - Issue not found
- `u11` - Certifier not found
- `u12` - Batch already certified

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit pull request

## 📄 License

MIT License - see LICENSE file for details.

---

Built with ❤️ for transparent and sustainable rice supply chains 🌾
