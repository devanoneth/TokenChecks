import * as dotenv from "dotenv";
import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "solidity-coverage";
import token from "./scripts/token";

dotenv.config();

task("token", "Checks the passed token").addPositionalParam("address", "Address of token").setAction(token);

const config: HardhatUserConfig = {
  solidity: "0.8.10",
  networks: {
    hardhat: {
      forking: {
        url: process.env.MAINNET_URL || "",
        blockNumber: 13904050,
      },
    },
    mainnet: {
      url: process.env.MAINNET_URL || "",
    },
  },
};

export default config;
