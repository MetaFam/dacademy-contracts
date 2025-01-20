import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';

export const NETWORK_NAME: Record<number, string> = {
  10: 'Optimism',
  100: 'Gnosis Chain',
  137: 'Polygon Mainnet',
  42161: 'Arbitrum One',
  11155111: 'Sepolia Testnet',
  17000: 'Holesky Testnet',
  31337: 'Hardhat Chain',
  11155420: 'Optimistic Sepolia Testnet',
};

export const NETWORK_CURRENCY: Record<number, string> = {
  10: 'OETH',
  100: 'xDAI',
  137: 'MATIC',
  42161: 'ETH',
  11155111: 'SepoliaETH',
  17000: 'HoleskyETH',
  31337: 'HardhatETH',
  11155420: 'OETH',
};

export type DeploymentInfo = {
  network: string;
  factory: string;
  implemention: string;
  txHash: string;
  blockNumber: string;
};

export const TREASURY_ADDRESS: Record<string, string> = {
  10: '0x19a8eb80c1483CEAA1278B16C5D5eF0104F85905', // dan13.eth
  100: '0xcDba6263aC0a162848380A1eD117B48D973EABFC', // gnosis safe
  137: '0xcDba6263aC0a162848380A1eD117B48D973EABFC', // gnosis safe
  42161: '0x19a8eb80c1483CEAA1278B16C5D5eF0104F85905', // dan13.eth
  17000: '0x19a8eb80c1483CEAA1278B16C5D5eF0104F85905', // dan13.eth
  11155111: '0x19a8eb80c1483CEAA1278B16C5D5eF0104F85905', // dan13.eth
  11155420: '0xEb4E3e9fA819E69e5Df4ea35b9C7973062C96de9', // dys.metagame.wtf
  31337: '0xffffffffffffffffffffffffffffffffffffffff',
};

export const PAYMENT_TOKEN: Record<string, string> = {
  10: '0x7f5c764cbc14f9669b88837ca1490cca17c31607', // USDC
  100: '0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83', // USDC
  137: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', // USDC
  42161: '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8', // USDC
  31337: '0xffffffffffffffffffffffffffffffffffffffff',
  11155111: '0x57B9f2c192BBfa5CAbc79A683435990FEa665861', // TOKEN
  11155420: '0x62c021e584702C40D0c14923ba6934791a8DaaD3', // OP
  17000: '0x59730da9b5f93fe1e1fd7d62f94b787ecc7feef1', // TOKEN
};

// export const DEFAULT_UPGRADE_FEE = 10000000 // 10 USDC with 6 decimals
export const DEFAULT_UPGRADE_FEE = 0;

export type SetupValues = {
  chainId: number;
  deployer: SignerWithAddress;
  address: string;
  balance: BigNumber;
};

export const validateSetup = async (): Promise<SetupValues> => {
  const [deployer] = await ethers.getSigners();
  const address = await deployer.getAddress();
  if (!deployer.provider) {
    throw new Error('Provider not found for network.');
  }
  const { chainId } = await deployer.provider.getNetwork();
  console.log('Chain ID:', chainId);
  console.log('Network:', NETWORK_NAME[chainId]);
  console.log('JSON-RPC:', deployer.provider.connection.url);
  if (!Object.keys(NETWORK_NAME).includes(chainId.toString())) {
    throw new Error('Unsupported network.');
  }
  console.log('Account Address:', address);
  const balance = await deployer.provider.getBalance(address);
  console.log(
    'Account Balance:',
    ethers.utils.formatEther(balance),
    NETWORK_CURRENCY[chainId],
  );

  return { chainId, deployer, address, balance };
};
