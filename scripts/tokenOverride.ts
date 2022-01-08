import { HardhatRuntimeEnvironment } from "hardhat/types";
import { promises as fs } from "fs";

const callingAddress = "0x0000000000000000000000000000000000000124";
const from = "0xda9dfa130df4de4673b89022ee50ff26f6ea73cf";

interface TokenParams {
  address: string;
}

// Here, we use geth's state override set in eth_call to really simulate the blockchain
export default async function tokenOverride(params: TokenParams, hre: HardhatRuntimeEnvironment): Promise<void> {
  const routerAddress = "0x7a250d5630b4cf539739df2c5dacb4c659f2488d";
  const ethers = hre.ethers;
  const utils = ethers.utils;

  const token = await ethers.getContractAt("ERC20", params.address);
  console.log(`Check token ${params.address} with name ${await token.name()}`);

  try {
    const ToleranceCheckOverrideDeployedBytecode = JSON.parse(
      await fs.readFile("./artifacts/contracts/ToleranceCheckOverride.sol/ToleranceCheckOverride.json", "utf-8"),
    ).deployedBytecode;

    const ToleranceCheckOverride = await ethers.getContractFactory("ToleranceCheckOverride");
    const functionData = ToleranceCheckOverride.interface.encodeFunctionData("checkToken", [
      routerAddress,
      params.address,
      utils.parseEther("0.01"),
    ]);

    const returnedData = await ethers.provider.send("eth_call", [
      {
        data: functionData,
        to: callingAddress,
      },
      "latest",
      {
        // state override set, the famous 3rd param of `eth_call` https://twitter.com/libevm/status/1476791869585588224
        // we set the bytecode to the deployed bytecode of our "tolerance check override" contract
        [callingAddress]: {
          code: ToleranceCheckOverrideDeployedBytecode,
          balance: utils.hexStripZeros(utils.parseEther("1").toHexString()),
        },
      },
    ]);

    if (returnedData === "0x01") {
      console.log("PASSED ToleranceCheck");
    } else {
      console.error("FAILED ToleranceCheck");
    }
  } catch (e) {
    console.error("FAILED ToleranceCheck");
  }
}
