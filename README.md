# Prediction-Market-for-Real-World-Events

## Project Description
**Prediction-Market-for-Real-World-Events** is a decentralized smart contract application built with Solidity that enables users to create and participate in prediction markets for real-world events. Using blockchain technology, the platform ensures transparency, immutability, and trustless interactions among participants.

## Project Vision
The project envisions a transparent and censorship-resistant platform where users can forecast outcomes of future events — such as elections, sports games, or economic indicators — and stake tokens on their predictions. By crowdsourcing knowledge and leveraging financial incentives, this platform aims to produce more accurate event forecasts than traditional methods.

## Key Features
- **Create Market:** Anyone can initiate a prediction market for a specific real-world event.
- **Place Bets:** Users can place bets on available outcomes with ETH or tokens.
- **Resolve Market:** Only the admin or oracle can resolve the outcome and distribute winnings accordingly.
- **Transparency & Security:** All transactions and logic are executed via smart contracts on the blockchain.

## Future Scope
- Integrate a decentralized oracle (like Chainlink) for automated market resolution.
- Add support for ERC20 tokens instead of native ETH.
- Build a React.js front-end interface for user interaction.
- Implement reputation systems for market creators.
- Expand to multi-chain support (e.g., Ethereum, Polygon, Base).

---

## Project Setup

### Prerequisites
- Node.js (v14+)
- npm or yarn
- Hardhat
- MetaMask or compatible wallet for testing

### Installation
```bash
npm install
require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    coreTestnet2: {
      url: process.env.RPC_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};


Contract Address:0xCd252420f88cE10b5000Af6e0fb0313da2E762e1


![image](https://github.com/user-attachments/assets/c11c2f9c-3882-4370-8fb4-6702b1f27bfc)
