import { ethers } from "hardhat";

const verifyStr = "npx hardhat verify --network";

async function main() {
  // const MockToken = await ethers.getContractFactory("MockToken");
  // const mUSDT = await MockToken.deploy("MockUSDT", "USDT", 6);
  // const mUsdtAddr = await mUSDT.getAddress();
  // console.log("MockUSDT", mUsdtAddr);
  // console.log(
  //   verifyStr,
  //   process.env.HARDHAT_NETWORK,
  //   mUsdtAddr,
  //   "MockUSDT",
  //   "USDT"
  // );

  const UserRegistar = await ethers.getContractFactory("UserRegistar");
  const userRegistar = await UserRegistar.deploy();
  const userRegistarAddr = await userRegistar.getAddress();
  console.log("UserRegistar", userRegistarAddr);
  console.log(verifyStr, process.env.HARDHAT_NETWORK, userRegistarAddr);

  const mUsdtAddr = "0xeFd73479d675D760ecd0a19c18eB16657327882A";
  // const userRegistarAddr = "0xeafc4f68773B9e130678267105c5df65c44B5E9f";

  const referralFee = 30000;
  const vrfCoordinator = "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625";
  const keyHash =
    "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c";
  const subId = 10621;
  const PoolManager = await ethers.getContractFactory("PoolManager");
  const poolManager = await PoolManager.deploy(
    referralFee,
    mUsdtAddr,
    userRegistarAddr,
    vrfCoordinator,
    keyHash,
    subId
  );
  const poolManagerAddr = await poolManager.getAddress();
  console.log("PoolManager", poolManagerAddr);
  console.log(
    verifyStr,
    process.env.HARDHAT_NETWORK,
    poolManagerAddr,
    referralFee,
    mUsdtAddr,
    userRegistarAddr,
    vrfCoordinator,
    keyHash,
    subId
  );

  // const poolManager = await ethers.getContractAt(
  //   "PoolManager",
  //   "0xADe9407d5233AcdBd93404a83432a3110164a218"
  // );
  // await poolManager.createPool(
  //   2,
  //   80000000,
  //   1000000,
  //   3600 * 12,
  //   1800,
  //   1714012200
  // );
  // await poolManager.createPool(
  //   3,
  //   850000000,
  //   1000000,
  //   3600 * 24,
  //   1800,
  //   1714012200
  // );
  // console.log("Create Pool Success");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
