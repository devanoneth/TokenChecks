import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { IERC20, IUniswapV2Router02 } from "../typechain";
const utils = ethers.utils;

const deadlineBuffer = 180;
const calleAddress = "0x0000000000000000000000000000000000000123";

describe("FlashSwap", async function () {
  let deployer: SignerWithAddress;
  let uniRouter: IUniswapV2Router02;
  let sushiRouter: IUniswapV2Router02;
  let dai: IERC20;
  let weth: IERC20;

  let deadline: number;

  it("Can setup", async function () {
    [deployer] = await ethers.getSigners();

    uniRouter = await ethers.getContractAt("IUniswapV2Router02", "0x7a250d5630b4cf539739df2c5dacb4c659f2488d");
    sushiRouter = await ethers.getContractAt("IUniswapV2Router02", "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F");
    weth = await ethers.getContractAt("IERC20", await uniRouter.WETH());
    dai = await ethers.getContractAt("IERC20", "0x6b175474e89094c44da98b954eedeac495271d0f");

    deadline = (await ethers.provider.getBlock("latest")).timestamp + deadlineBuffer;
  });

  // it("Can detect when no arb opportunity exists", async function () {
  //   const UniswapV2FlashCallee = await ethers.getContractFactory("UniswapV2FlashCallee");
  //   // This cannot have constructor args as the constructor won't be called
  //   // But you could sub in any other chains / DEXs addresses into the deploy data
  //   const calleDeployData = UniswapV2FlashCallee.getDeployTransaction().data;

  //   const UniswapV2FlashCaller = await ethers.getContractFactory("UniswapV2FlashCaller");
  //   const callerDeployData = UniswapV2FlashCaller.getDeployTransaction(router.address, feeERC20.address).data;

  //   const returnedData = await ethers.provider.call({
  //     data: deployData,
  //     value: utils.parseEther("1"),
  //   });

  //   // 0x00 = arb opportunity does not exists
  //   expect(returnedData).to.be.eq("0x00");
  // });

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
    const UniswapV2FlashCallee = await ethers.getContractFactory("UniswapV2FlashCallee");
    const Test = await ethers.getContractFactory("TestContract");

    const UniswapV2FlashCaller = await ethers.getContractFactory("UniswapV2FlashCaller");

    // We expect a 1 ETH arb opp
    const daiAmount = (await uniRouter.getAmountsOut(utils.parseEther("1"), [weth.address, dai.address]))[1];
    const deployData = UniswapV2FlashCaller.getDeployTransaction(
      uniRouter.address,
      calleAddress,
      dai.address,
      weth.address,
      daiAmount,
      "0",
    ).data;

    await ethers.provider.send("hardhat_setCode", [calleAddress, Test.bytecode]);
    // console.log(Test.bytecode);

    // const code = await ethers.provider.getCode(calleAddress);
    // console.log(code);

    // Here we cannot use ethers.js' `provider.call` method as it does not accept the 3rd param
    // Would be nice if it did (PR idea)
    // const data = Test.interface.encodeFunctionData("tryCall");
    // console.log(data);
    const returnedData = await ethers.provider.call({
      data: deployData,
    });

    console.log(returnedData);
    // console.log(Test.interface.decodeFunctionResult("tryCall", returnedData));

    // 0x01 = arb opportunity exists
    expect(returnedData).to.be.eq("0x01");
  });
});
