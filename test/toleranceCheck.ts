import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { IUniswapV2Router02 } from "../typechain";
const utils = ethers.utils;

const deadlineBuffer = 180;

describe("ToleranceCheck", async function () {
  let deployer: SignerWithAddress;
  let router: IUniswapV2Router02;

  let deadline: number;

  it("Can setup", async function () {
    [deployer] = await ethers.getSigners();

    router = await ethers.getContractAt("IUniswapV2Router02", "0x7a250d5630b4cf539739df2c5dacb4c659f2488d");

    deadline = (await ethers.provider.getBlock("latest")).timestamp + deadlineBuffer;
  });

  it("Should work with good erc20", async function () {
    const GoodERC20 = await ethers.getContractFactory("GoodERC20");
    const goodERC20 = await GoodERC20.deploy();
    await goodERC20.deployed();

    await goodERC20.approve(router.address, utils.parseEther("1000"));
    await router.addLiquidityETH(
      goodERC20.address,
      utils.parseEther("1000"),
      utils.parseEther("1000"),
      utils.parseEther("5"),
      deployer.address,
      deadline,
      { value: utils.parseEther("5") },
    );

    const ToleranceCheck = await ethers.getContractFactory("ToleranceCheck");
    const deployData = ToleranceCheck.getDeployTransaction(
      router.address,
      goodERC20.address,
      utils.parseEther("0.005"),
    ).data;
    const returnedData = await ethers.provider.call({
      data: deployData,
      value: utils.parseEther("1"),
    });

    // 0x01 = true = successful
    expect(returnedData).to.be.eq("0x01");
  });

  it("Should successfully detect bad erc20", async function () {
    const BadERC20 = await ethers.getContractFactory("BadERC20");
    const badERC20 = await BadERC20.deploy(router.address);
    await badERC20.deployed();

    await badERC20.approve(router.address, utils.parseEther("1000"));
    await router.addLiquidityETH(
      badERC20.address,
      utils.parseEther("1000"),
      utils.parseEther("1000"),
      utils.parseEther("5"),
      deployer.address,
      deadline,
      { value: utils.parseEther("5") },
    );

    const ToleranceCheck = await ethers.getContractFactory("ToleranceCheck");
    const deployData = ToleranceCheck.getDeployTransaction(
      router.address,
      badERC20.address,
      utils.parseEther("0.005"),
    ).data;

    // reverts = fail
    await expect(ethers.provider.call({ data: deployData, value: utils.parseEther("1") })).to.be.reverted;
  });
});
