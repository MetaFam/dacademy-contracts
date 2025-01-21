import '@nomicfoundation/hardhat-verify';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import 'solidity-coverage';

import fs from 'node:fs';

import dotenv from 'dotenv';
import { HardhatUserConfig, task } from 'hardhat/config';

dotenv.config();

let accounts: any = process.env.MNEMONIC
  ? { mnemonic: process.env.MNEMONIC }
  : null;
accounts ??= process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : null;

if (!accounts) {
  const mnemonicFile = 'mnemonic.txt';
  if (fs.existsSync(mnemonicFile)) {
    accounts = {
      mnemonic: fs.readFileSync(mnemonicFile).toString().trim(),
    };
  }
}

if (!accounts) {
  console.error('invalid env variable: PRIVATE_KEY or MNEMONIC');
  process.exit(1);
}

task('accounts', 'Prints the list of accounts', async (_args, hre) => {
  const accounts = await hre.ethers.getSigners();
  const provider = hre.ethers.provider;

  for (const { address } of accounts) {
    const balance = await provider.getBalance(address);
    console.info(`${address}: ${balance}`);
  }
});

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.28',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1_000_000,
          },
        },
      },
    ],
  },
  networks: {
    locahost: {
      url: 'http://localhost:8545',
      accounts,
    },
    optimism: {
      url: 'https://mainnet.optimism.io',
      accounts,
    },
    opSepolia: {
      url: 'https://sepolia.optimism.io',
      accounts,
    },
    gnosis: {
      url: `https://rpc.gnosischain.com`,
      accounts,
    },
    polygon: {
      url: 'https://rpc-mainnet.maticvigil.com',
      accounts,
    },
    arbitrumOne: {
      url: 'https://arb1.arbitrum.io/rpc',
      accounts,
    },
    sepolia: {
      url: 'https://1rpc.io/sepolia',
      accounts,
    },
    holesky: {
      url: 'https://1rpc.io/holesky',
      accounts,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === 'true',
    currency: 'USD',
  },
  etherscan: {
    apiKey: {
      optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_API_KEY!,
      opSepolia: process.env.OPTIMISTIC_ETHERSCAN_API_KEY!,
      polygon: process.env.POLYGONSCAN_API_KEY!,
      gnosis: process.env.GNOSISSCAN_API_KEY!,
      arbitrumOne: process.env.ARBISCAN_API_KEY!,
      sepolia: process.env.ETHERSCAN_API_KEY!,
      holesky: process.env.ETHERSCAN_API_KEY!,
    },
    customChains: [
      {
        network: 'holesky',
        chainId: 17000,
        urls: {
          apiURL: 'https://api-holesky.etherscan.io/api',
          browserURL: 'https://holesky.etherscan.io',
        },
      },
      {
        network: 'opSepolia',
        chainId: 11155420,
        urls: {
          apiURL: 'https://api-sepolia-optimistic.etherscan.io/api',
          browserURL: 'https://sepolia-optimistic.etherscan.io',
        },
      },
    ],
  },
  typechain: {
    outDir: 'types',
  },
};

export default config;
