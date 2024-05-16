import { ethers } from "hardhat";

const verifyStr = "npx hardhat verify --network";

async function main() {
  const MockToken = await ethers.getContractFactory("MockToken");
  const mUSDT = await MockToken.deploy("MockUSDT", "USDT", 6);
  const mUsdtAddr = await mUSDT.getAddress();
  console.log("MockUSDT", mUsdtAddr);
  console.log(
    verifyStr,
    process.env.HARDHAT_NETWORK,
    mUsdtAddr,
    "MockUSDT",
    "USDT",
    6
  );

  const UserRegistar = await ethers.getContractFactory("UserRegistar");
  const userRegistar = await UserRegistar.deploy();
  const userRegistarAddr = await userRegistar.getAddress();
  console.log("UserRegistar", userRegistarAddr);
  console.log(verifyStr, process.env.HARDHAT_NETWORK, userRegistarAddr);

  // const mUsdtAddr = "0x88B53102DA1baFa10a4163FFfb9649E1001ce879";
  // const userRegistarAddr = "0x28aAec993079403D82d7Ec6A0d8b5bB16317E08b";

  const referralFee = 30000;

  const PoolManager = await ethers.getContractFactory("PoolManager");
  const poolManager = await PoolManager.deploy(
    referralFee,
    mUsdtAddr,
    userRegistarAddr
  );
  const poolManagerAddr = await poolManager.getAddress();
  console.log("PoolManager", poolManagerAddr);
  console.log(
    verifyStr,
    process.env.HARDHAT_NETWORK,
    poolManagerAddr,
    referralFee,
    mUsdtAddr,
    userRegistarAddr
  );

  const vrfCoordinator = "0x3C0Ca683b403E37668AE3DC4FB62F4B29B6f7a3e";
  const keyHash =
    "0x9e9e46732b32662b9adc6f3abdf6c5e926a666d174a4d6b8e39c4cca76a38897";
  const subId = ethers.toBigInt(
    "17062792931732899628613066706992643234929337686189570945199697297915397000530"
  );
  const requestConfirmations = 1;
  const callbackGasLimit = 2500000;

  const VRFConsumer = await ethers.getContractFactory("VRFConsumer");
  const vrfConsumer = await VRFConsumer.deploy(
    poolManagerAddr,
    vrfCoordinator,
    keyHash,
    subId,
    requestConfirmations,
    callbackGasLimit
  );
  const vrfConsumerAddr = await vrfConsumer.getAddress();
  console.log("VRFConsumer", vrfConsumerAddr);
  console.log(
    verifyStr,
    process.env.HARDHAT_NETWORK,
    vrfConsumerAddr,
    poolManagerAddr,
    vrfCoordinator,
    keyHash,
    subId,
    requestConfirmations,
    callbackGasLimit
  );

  await poolManager.setVRFConsumer(vrfConsumerAddr);
  console.log("setVRFConsumer success");

  // const poolManager = await ethers.getContractAt(
  //   "PoolManager",
  //   "0x6Ea249D3087F64472e689036648416c3FF685FBa"
  // );
  // await poolManager.createPool(
  //   2,
  //   80000000,
  //   1000000,
  //   3600 * 12,
  //   1800,
  //   1715745300
  // );
  // await poolManager.createPool(
  //   3,
  //   850000000,
  //   1000000,
  //   3600 * 24,
  //   1800,
  //   1715745300
  // );
  // console.log("Create Pool Success");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
