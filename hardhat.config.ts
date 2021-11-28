import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.4",
      },
      {
        version: "0.6.12",
      },
    ],
  },
  networks: {
    localhost: {
      url: process.env.RSK_LOCAL || "",
    },
    testnet: {
      chainId: 31,
      url: process.env.RSK_TESTNET || "",
      accounts: [process.env.PRIVATE_KEY || ''],
    },
  },
};

export default config;
