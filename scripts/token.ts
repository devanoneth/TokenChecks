import { HardhatRuntimeEnvironment } from "hardhat/types";

interface TokenParams {
  address: string;
}

export default async function token(params: TokenParams, hre: HardhatRuntimeEnvironment): Promise<void> {
  const routerAddress = "0x7a250d5630b4cf539739df2c5dacb4c659f2488d";
  const ethers = hre.ethers;
  const utils = ethers.utils;

  const token = await ethers.getContractAt("ERC20", params.address);
  console.log(`Check token ${params.address} with name ${await token.name()}`);

  try {
    const ToleranceCheck = await ethers.getContractFactory("ToleranceCheck");
    const deployData = ToleranceCheck.getDeployTransaction(
      routerAddress,
      params.address,
      utils.parseEther("0.01"),
    ).data;

    const returnedData = await ethers.provider.call({
      data: deployData,
      value: utils.parseEther("1"),
    });

    if (returnedData === "0x01") {
      console.log("PASSED ToleranceCheck");
    } else {
      console.error("FAILED ToleranceCheck");
    }
  } catch (e) {
    console.error("FAILED ToleranceCheck");
  }

  try {
    const InternalFee = await ethers.getContractFactory("InternalFee");
    const deployData = InternalFee.getDeployTransaction(routerAddress, params.address).data;
    const returnedData = await ethers.provider.call({
      data: deployData,
      value: utils.parseEther("1"),
    });

    if (returnedData === "0x01") {
      console.log("PASSED InternalFee");
    } else {
      console.error("FAILED InternalFee");
    }
  } catch (e) {
    console.error("FAILED InternalFee");
  }
}
