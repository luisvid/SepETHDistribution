# SepoliaETH Distributor PoC

This project is a Proof of Concept (PoC) designed for educational purposes to teach blockchain programming with Solidity
from scratch. The main problem it addresses is the difficulty students face in obtaining Sepolia ETH from faucets due to
stringent requirements. This PoC allows for the distribution of Sepolia ETH from a centralized account that accumulates
ETH over time or through donations from other developers.

## Project Overview

The first iteration of this project includes a smart contract that distributes Sepolia ETH in batches and a TypeScript
script that interacts with the deployed smart contract. Future iterations will include a UI and backend to create a
complete Dapp, serving as a comprehensive example for blockchain programming classes.

## Features

### BatchSepoliaDistributor Smart Contract

- **Initialization**: Sets an initial distribution amount.
- **Distribution Management**: Allows the owner to set distribution amounts, submit recipient addresses, distribute ETH
  in batches, clear addresses, and withdraw contract balance.
- **Event Emissions**: Emits events for updates to distribution amounts, address submissions, batch distributions, and
  more.
- **Error Handling**: Includes error messages for issues like insufficient contract balance and no recipients.

### distributeEth.ts Script

- **Network Selection**: Supports deployment and interaction with both Anvil and Sepolia test networks.
- **Address Management**: Reads addresses from a file, submits them for distribution, and handles batch distribution.
- **Contract Interaction**: Sets distribution amounts, funds the contract, checks balances, and withdraws remaining ETH.
- **Command-Line Interface**: Uses yargs for command-line argument parsing to specify network and address file.

## Getting Started

To successfully deploy and interact with the SepoliaETH Distributor, you will need the following:

- **MetaMask Wallet**: Ensure you have a MetaMask wallet loaded with testnet ETH for transactions on Ethereum test
  networks.
- **Infura Account and API Key**: Obtain an Infura account and API key to access Ethereum networks and manage
  deployments and interactions with smart contracts.
- **Contract Deployment Tools**: Use tools like Foundry or Hardhat for deploying contracts. This project uses
  [PaulRBerg's foundry-template](https://github.com/PaulRBerg/foundry-template), optimized for developing Solidity smart
  contracts with Foundry.

These tools and accounts will equip you with the necessary environment to launch and test the SepoliaETH Distributor
effectively.

### Installation

1. Clone the repository:
   ```sh
   git clone <repository-url>
   ```
2. Install dependencies:
   ```sh
   bun install
   ```
3. Rename `.env.example` to `.env` and replace the placeholder values with actual values:
   ```sh
   mv .env.example .env
   ```
4. Compile the contract:
   ```sh
   forge build
   ```
5. Run tests:
   ```sh
   forge test
   ```

### Deploy

#### Deploy to Anvil

1. Deploy the contract:

   ```sh
   forge script script/DeployDistributor.s.sol --broadcast --fork-url http://localhost:8545
   ```

2. Extract the ABI from the build artifacts:

   ```sh
   cat out/BatchSepoliaDistributor.sol/BatchSepoliaDistributor.json | jq .abi > abi/contracts/BatchSepoliaDistributor.sol/BatchSepoliaDistributor.json
   ```

3. Replace the contract address in the `distributeEth.ts` script with the deployed contract address.

4. Interact with the deployed contract using the provided addresses:
   ```sh
   npx ts-node tsScript/distributeEth.ts --network anvil --addressFile ./addresses.txt
   ```

#### Deploy to Sepolia

1. Load environment variables:

   ```sh
   source .env
   ```

2. Deploy and verify the contract:

   ```sh
   forge script script/DeployDistributor.s.sol --rpc-url sepolia --broadcast --verify -vvvv
   ```

3. Replace the contract address in the `distributeEth.ts` script with the deployed contract address.

4. Interact with the deployed contract using the provided addresses:
   ```sh
   npx ts-node tsScript/distributeEth.ts --network sepolia --addressFile ./addresses.txt
   ```

## Conclusion

This PoC project provides a foundation for teaching blockchain programming with Solidity by solving the issue of
obtaining Sepolia ETH for students. By including both a smart contract and a script for interaction, it offers a
practical example for students to understand and build upon. Future enhancements will further develop this project into
a comprehensive Dapp, enriching the learning experience.
