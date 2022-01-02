import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { IERC20, IUniswapV2Router02 } from "../typechain";
import { deployedBytecode as UniswapV2FlashCalleeDeployedBytecode } from "../artifacts/contracts/UniswapV2FlashCallee.sol/UniswapV2FlashCallee.json";
import { BytesLike } from "ethers";
const utils = ethers.utils;

const deadlineBuffer = 180;
const calleAddress = "0x0000000000000000000000000000000000000123";
const callingAddress = "0x0000000000000000000000000000000000000124";

describe("FlashSwap", async function () {
  let deployer: SignerWithAddress;
  let uniRouter: IUniswapV2Router02;
  let sushiRouter: IUniswapV2Router02;
  let dai: IERC20;
  let weth: IERC20;

  let deadline: number;

  let deployData: BytesLike | undefined;

  it("Can setup", async function () {
    [deployer] = await ethers.getSigners();

    uniRouter = await ethers.getContractAt("IUniswapV2Router02", "0x7a250d5630b4cf539739df2c5dacb4c659f2488d");
    sushiRouter = await ethers.getContractAt("IUniswapV2Router02", "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F");
    weth = await ethers.getContractAt("IERC20", await uniRouter.WETH());
    dai = await ethers.getContractAt("IERC20", "0x6b175474e89094c44da98b954eedeac495271d0f");

    deadline = (await ethers.provider.getBlock("latest")).timestamp + deadlineBuffer;

    // IMPORTANT!
    // Instead of using geth's state override set, we use hardhat's set code method.
    // When running against a real network, you should of course use the override set instead.
    // Look at `scripts/flashSwap.ts` for how to use the state override set against a real network.
    // We could just deploy it in our hardhat fork, but better to use the set code method
    // so that we also have to deal with the issues around not having any storate slots set.
    // Note: you could find/replace any address values that you've put in your contract here
    // or, you could set the storage slots. It could be worth making a library to help with all of this actually...
    await ethers.provider.send("hardhat_setCode", [calleAddress, UniswapV2FlashCalleeDeployedBytecode]);

    // This is the initator of the flash swap check
    const UniswapV2FlashCaller = await ethers.getContractFactory("UniswapV2FlashCaller");
    // Get deploy data to run the check without actually deploying anything
    deployData = UniswapV2FlashCaller.getDeployTransaction(
      uniRouter.address,
      calleAddress,
      dai.address,
      weth.address,
      utils.parseEther("10"), // we are checking for a tiny opportunity here, 10 DAI
      "0",
    ).data;
  });

  it("Can detect when no arb opportunity exists", async function () {
    const returnedDataPromise = ethers.provider.call({
      data: deployData,
      from: callingAddress,
      nonce: "0x0", // forcing the nonce so that we get the same address from CREATE for UniswapV2FlashCaller
    });

    // reverts = fail = no arb opportunity exists
    await expect(returnedDataPromise).to.be.reverted;
  });

  it("Create arb opportunity", async function () {
    const initialBalance = await dai.balanceOf(deployer.address);

    // Big swap to create arb opp
    await sushiRouter.swapExactETHForTokens(
      0, // don't care how much we get
      [weth.address, dai.address],
      deployer.address,
      deadline,
      { value: utils.parseEther("100") },
    );

    expect(await dai.balanceOf(deployer.address)).to.be.gt(initialBalance);
  });

  it("Can detect when arb opportunity exists", async function () {
    const returnedData = await ethers.provider.call({
      data: deployData,
      from: callingAddress,
      nonce: "0x0", // forcing the nonce so that we get the same address from CREATE for UniswapV2FlashCaller
    });

    // 0x01 = arb opportunity exists
    expect(returnedData).to.be.eq("0x01");
  });
});
