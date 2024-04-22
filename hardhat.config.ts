import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    sepolia: {
      url: vars.get("SEPOLIA_URL"),
      accounts: [vars.get("PRIVATE_KEY")],
    },
    arbitrum_sepolia: {
      url: vars.get("ARBITRUM_SEPOLIA_URL"),
      accounts: [vars.get("PRIVATE_KEY")],
    },
  },
  etherscan: {
    apiKey: vars.get("ETHERSCAN_API_KEY"),
    // apiKey: vars.get("ARBISCAN_API_KEY"),
  },
};

export default config;
