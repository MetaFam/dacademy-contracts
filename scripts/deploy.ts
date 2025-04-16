import { execSync } from 'node:child_process';
import fs from 'node:fs';

import { ethers, network, run } from 'hardhat';

import { BookFactory } from '../types';
import {
  DEFAULT_UPGRADE_FEE,
  NETWORK_CURRENCY,
  NETWORK_NAME,
  PAYMENT_TOKEN,
  TREASURY_ADDRESS,
  validateSetup,
} from './utils';

async function main() {
  const { chainId, deployer, address, balance } = await validateSetup();
  const commitHash = execSync('git rev-parse --short HEAD', {
    encoding: 'utf-8',
  }).trim();

  // if(TREASURY_ADDRESS[chainId] == null) {
  //   throw new Error('`TREASURY_ADDRESS` not found.')
  // }
  // if(PAYMENT_TOKEN[bookId] == null) {
  //   throw new Error('`PAYMENT_TOKEN` not found.')
  // }
  if(!deployer.provider) {
    throw new Error('Provider not found for network.');
  }

  console.info('Deploying dAcademy:', NETWORK_NAME[chainId]);
  console.info('`git` Commit Hash:', commitHash);

  // const Book = await ethers.getContractFactory('Book');
  // const Shelf = await ethers.getContractFactory('Shelf');
  // const book = await Book.deploy();
  // const shelf = await Shelf.deploy();
  // await Promise.all([book.deployed(), shelf.deployed()]);
  // console.info('Chain Template Address:', book.address);
  // console.info('Shelf Template Address:', shelf.address);

  const BookFactory = await ethers.getContractFactory(
    'BookFactory',
  );
  const factoryArgs = [
    // book.address,
    // shelf.address,
    address,
    // TREASURY_ADDRESS[chainId],
    // PAYMENT_TOKEN[chainId],
    // DEFAULT_UPGRADE_FEE,
  ];
  const factory = (await BookFactory.deploy(
    ...factoryArgs,
  )) as BookFactory;
  await factory.deployed();
  console.info('Factory Address:', factory.address);

  const bookTokenAddress = await factory.bookToken();
  console.info('Token Address:', bookTokenAddress);

  const txHash = factory.deployTransaction.hash;
  console.info('Transaction Hash:', txHash);

  const receipt = await deployer.provider.getTransactionReceipt(txHash);
  console.info('Block Number:', receipt.blockNumber);

  const afterBalance = await deployer.provider.getBalance(address);
  const gasUsed = balance.sub(afterBalance);
  console.info(
    'Gas Used:',
    ethers.utils.formatEther(gasUsed),
    NETWORK_CURRENCY[chainId],
  );
  console.info(
    'Account Balance:',
    ethers.utils.formatEther(afterBalance),
    NETWORK_CURRENCY[chainId],
  );

  if(chainId === 31337) {
    console.debug(
      'Skipping writing deployment info & verification for local network.',
    );
    return;
  }

  try {
    const deploymentInfo = {
      network: network.name,
      version: commitHash,
      factory: factory.address,
      token: bookTokenAddress,
      templates: {
        book: await factory.bookTemplate(),
        shelf: await factory.shelfTemplate(),
        collection: await factory.collectionTemplate(),
      },
      txHash,
      blockNumber: receipt.blockNumber,
    };

    const outFile = `deployments/${network.name}.json`;
    fs.writeFileSync(outFile, JSON.stringify(deploymentInfo, null, 2));
    console.info('Wrote Deployment Info:', outFile);

    console.debug('Waiting for contracts to be indexed…');
    await factory.deployTransaction.wait(10);

    console.debug('Verifying Contracts…');

    await run('verify:verify', {
      address: await factory.bookTemplate(),
      constructorArguments: [],
    });

    await run('verify:verify', {
      address: await factory.shelfTemplate(),
      constructorArguments: [],
      contract: "contracts/Shelf.sol:Shelf",
    });

    await run('verify:verify', {
      address: await factory.collectionTemplate(),
      constructorArguments: [],
    });

    await run('verify:verify', {
      address: factory.address,
      constructorArguments: factoryArgs,
    });

    await run('verify:verify', {
      address: bookTokenAddress,
      constructorArguments: [],
    });
  } catch (error) {
    console.error('Error Verifying Contracts:', error);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error({ error });
    process.exit(1);
  });
