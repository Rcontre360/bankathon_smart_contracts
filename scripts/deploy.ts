// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import {ethers} from "hardhat";
import fs from 'fs'

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const LendingPool = await ethers.getContractFactory("LendingPool");
  const MockToken = await ethers.getContractFactory("MockToken");
  const token = await MockToken.deploy();
  const lending = await LendingPool.deploy(token.address);

  const lendToken = await lending.lendToken();

  console.log(`Token at ${token.address}. LendingPool at ${lending.address}. LendToken at ${lendToken}`);
  const configFileName = "deployed-addresses.json";
  const configData = JSON.stringify({
    stablecoin: token.address,
    lendToken: lendToken.address,
    lendingPool: lending.address,
  }, null, 2);
  fs.writeFileSync(configFileName, configData);
  console.log(`Generated ${configFileName}: ${configData}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
