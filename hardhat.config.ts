import * as dotenv from "dotenv";
import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "solidity-coverage";
import token from "./scripts/token";
import tokenOverride from "./scripts/tokenOverride";
import flashSwap from "./scripts/flashSwap";

dotenv.config();

task("token", "Checks the passed token").addPositionalParam("address", "Address of token").setAction(token);
task("token-override", "Checks the passed token using geth's state override set")
  .addPositionalParam("address", "Address of token")
  .setAction(tokenOverride);

task("flash", "Checks if a flash swap can be performed").setAction(flashSwap);

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
