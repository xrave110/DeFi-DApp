const { ethers } = require("hardhat");
require("dotenv").config({ path: ".env" });
const { CRYPTO_DEV_TOKEN_ADDRESS } = require("../constants");

async function main() {
  const cryptoDevTokenAddress = CRYPTO_DEV_TOKEN_ADDRESS;
  const exchangeContract = await ethers.getContractFactory("Exchange");
  const deployedExchangeContract = await exchangeContract.deploy(cryptoDevTokenAddress);
  await deployedExchangeContract.deployed();
  console.log("exchange Contract Address: ", deployedExchangeContract.address);
}

main()
  .then(() => { process.exit(0) })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
