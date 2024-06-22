import { ethers } from 'ethers';

// this script is to check if ethers is working properly
async function checkEthers() {
    try {
        // Using the default provider (homestead is the Ethereum mainnet)
        const provider = ethers.getDefaultProvider('homestead');

        // Fetching the latest block number
        const blockNumber = await provider.getBlockNumber();

        console.log(`Current block number: ${blockNumber}`);
    } catch (error) {
        console.error('Error accessing the Ethereum network:', error);
    }
}

checkEthers();
