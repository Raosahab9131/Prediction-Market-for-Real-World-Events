const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying PredictionMarket contract...");

  // Get the ContractFactory for our PredictionMarket contract
  const PredictionMarket = await ethers.getContractFactory("PredictionMarket");
  
  // Deploy the contract
  const predictionMarket = await PredictionMarket.deploy();

  // Wait for deployment to finish
  await predictionMarket.deployed();

  console.log(`PredictionMarket deployed to: ${predictionMarket.address}`);
  console.log("Deployment transaction:", predictionMarket.deployTransaction.hash);
  
  console.log("\nVerify with:");
  console.log(`npx hardhat verify --network core_testnet2 ${predictionMarket.address}`);
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
