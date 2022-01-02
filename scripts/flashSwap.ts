import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployedBytecode as UniswapV2FlashCalleeDeployedBytecode } from "../artifacts/contracts/UniswapV2FlashCallee.sol/UniswapV2FlashCallee.json";

const calleAddress = "0x0000000000000000000000000000000000000123";
const callingAddress = "0x0000000000000000000000000000000000000124";
const uniRouterAddress = "0x7a250d5630b4cf539739df2c5dacb4c659f2488d";
const daiAddress = "0x6b175474e89094c44da98b954eedeac495271d0f";
const wethAddress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";

interface FlashSwapParams {
  // here you could pass tokens to check
}

export default async function flash(params: FlashSwapParams, hre: HardhatRuntimeEnvironment): Promise<void> {
  const ethers = hre.ethers;
  const utils = ethers.utils;

  // This is the initator of the flash swap check
  const UniswapV2FlashCaller = await ethers.getContractFactory("UniswapV2FlashCaller");
  // Get deploy data to run the check without actually deploying anything
  const deployData = UniswapV2FlashCaller.getDeployTransaction(
    uniRouterAddress,
    calleAddress,
    daiAddress,
    wethAddress,
    utils.parseEther("10"),
    "0",
  ).data;

  try {
    const returnedData = await ethers.provider.send("eth_call", [
      {
        data: deployData,
        from: callingAddress,
        nonce: "0x0", // forcing the nonce so that we get the same address from CREATE for UniswapV2FlashCaller
      },
      "latest",
      {
        // state override set, the famous 3rd param of `eth_call`https://twitter.com/libevm/status/1476791869585588224
        [calleAddress]: {
          code: UniswapV2FlashCalleeDeployedBytecode,
        },
      },
    ]);

    if (returnedData === "0x01") {
      console.log("Arb opportunity found!");
    } else {
      console.error("No arb opportunity");
    }
  } catch (e) {
    console.error("No arb opportunity");
  }
}
