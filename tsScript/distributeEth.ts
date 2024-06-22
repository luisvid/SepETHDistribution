import { ethers } from "ethers";
import dotenv from "dotenv";
import yargs from "yargs/yargs";
import { hideBin } from "yargs/helpers";
import abi_Distribuitor from "../abi/contracts/BatchSepoliaDistributor.sol/BatchSepoliaDistributor.json";
import fs from "fs/promises";
import { log } from "console";

dotenv.config();

type NetworkName = "anvil" | "sepolia";

// Parse command-line arguments
const argv = yargs(hideBin(process.argv))
  .option("network", {
    type: "string",
    describe: "Specify the network to use (anvil or sepolia)",
    choices: ["anvil", "sepolia"],
    default: "anvil",
  })
  .option("addressFile", {
    type: "string",
    describe: "Path to the file containing addresses",
    demandOption: true,
  }).argv as { network: NetworkName; addressFile: string };

// Determine the network to use
const network: NetworkName = argv.network;

// Check if the required environment variables are set
const { PRIVATE_KEY, API_KEY_INFURA, PRIVATE_KEY_ANVIL } = process.env;
if (network === "anvil" && !PRIVATE_KEY_ANVIL) {
  throw new Error("Please set your PRIVATE_KEY_ANVIL in the .env file");
}
if (network === "sepolia" && (!PRIVATE_KEY || !API_KEY_INFURA)) {
  throw new Error("Please set your PRIVATE_KEY and API_KEY_INFURA in the .env file");
}

const privateKeys: Record<NetworkName, string> = {
  anvil: PRIVATE_KEY_ANVIL || "",
  sepolia: PRIVATE_KEY || "",
};

const rpcUrls: Record<NetworkName, string> = {
  anvil: "http://127.0.0.1:8545",
  sepolia: `https://sepolia.infura.io/v3/${API_KEY_INFURA}`,
};

// Define the addresses of the deployed contract on different networks
const addresses: Record<NetworkName, string> = {
  anvil: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
  sepolia: "0xYourSepoliaContractAddress",
};

const provider = new ethers.JsonRpcProvider(rpcUrls[network]);
const wallet = new ethers.Wallet(privateKeys[network], provider);
const ethDistribuitorAddress = addresses[network];

// Set up contract instances
const ethDistribuitor = new ethers.Contract(ethDistribuitorAddress, abi_Distribuitor, wallet);

// Function to read addresses from a file
async function readAddressesFromFile(filePath: string): Promise<string[]> {
  const fileContent = await fs.readFile(filePath, 'utf8');
  return fileContent.split(',').map(address => address.trim());
}

// Function to set the distribution amount
async function setDistributionAmount(amount: number) {
  try {
    const tx = await ethDistribuitor.setDistributionAmount(ethers.parseEther(amount.toString()));
    await tx.wait();
    console.log(`Distribution amount set to ${amount} ETH`);
  } catch (error) {
    console.error("Failed to set distribution amount:", error);
  }
}

// Function to submit a batch of addresses
async function submitAddresses(addresses: string[]) {
  try {
    const tx = await ethDistribuitor.submitAddresses(addresses);
    await tx.wait();
    console.log(`Submitted addresses: ${addresses.join(", ")}`);
  } catch (error) {
    console.error("Failed to submit addresses:", error);
  }
}

// Function to distribute SepoliaETH
async function distributeBatch() {
  try {
    const tx = await ethDistribuitor.distributeBatch();
    await tx.wait();
    console.log("Distributed SepoliaETH to all submitted addresses");
  } catch (error) {
    console.error("Failed to distribute SepoliaETH:", error);
  }
}

// Function to fund the contract
async function fundContract(amount: number) {
  try {
    const tx = await wallet.sendTransaction({
      to: ethDistribuitorAddress,
      value: ethers.parseEther(amount.toString()),
    });
    await tx.wait();
    console.log(`Funded contract with ${amount} ETH`);

    // check the contract balance
    await checkContractBalance();
  } catch (error) {
    console.error("Failed to fund contract:", error);
  }
}

// Check the contract balance
async function checkContractBalance() {
  try {
    const balance = await provider.getBalance(ethDistribuitorAddress);
    console.log(`Contract balance is ${ethers.formatEther(balance)} ETH`);
  } catch (error) {
    console.error("Failed to check contract balance:", error);
  }
}

async function main() {
  try {
    // Read addresses from the specified file
    const addresses = await readAddressesFromFile(argv.addressFile);

    // Set distribution amount to 10 ETH
    await setDistributionAmount(100); // Example: 0.01 ETH per address

    await submitAddresses(addresses);

    // Fund the contract with sufficient ETH
    await fundContract(1000); // Example: 1 ETH

    // Distribute SepoliaETH
    await distributeBatch();

    // Check the contract balance
    await checkContractBalance();

    // withdraw the contract balance back to the owner
    console.log("Withdrawing the contract balance back to the owner");
    const tx = await ethDistribuitor.withdraw();
    await tx.wait()
    console.log("Contract balance withdrawn back to the owner")


    // Check the contract balance
    await checkContractBalance();

  } catch (error) {
    console.error("Error in main execution:", error);
  }
}

main().catch(console.error);
