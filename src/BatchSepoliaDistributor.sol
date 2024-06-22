// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { console2 } from "forge-std/src/console2.sol";

/**
 * @title BatchSepoliaDistributor
 * @dev A smart contract for collecting addresses and distributing SepoliaETH in batches.
 */
contract BatchSepoliaDistributor is Ownable {
    uint256 public distributionAmount;
    address[] private recipients;

    event DistributionAmountUpdated(uint256 amount);
    event AddressSubmitted(address indexed recipient);
    event BatchDistributed(address[] recipients, uint256 amount);
    event AddressesSubmitted(address[] recipients);
    event AddressesCleared();
    event TransferFailed(address indexed recipient);
    event Withdrawal(address indexed to, uint256 amount);

    error AddressAlreadySubmitted(address addr);
    error InsufficientContractBalance(uint256 required, uint256 available);
    error NoRecipients();
    error ContractBalanceZero();
    error WithdrawalFailed();

    /**
     * @dev Initializes the contract with an initial distribution amount.
     * @param _distributionAmount The amount of SepoliaETH to distribute per address.
     */
    constructor(uint256 _distributionAmount) Ownable(msg.sender) {
        setDistributionAmount(_distributionAmount);
    }

    /**
     * @notice Sets the distribution amount.
     * @dev Only the owner can call this function.
     * @param _distributionAmount The new amount to distribute per address.
     */
    function setDistributionAmount(uint256 _distributionAmount) public onlyOwner {
        distributionAmount = _distributionAmount;
        console2.log("Distribution amount updated to %d", _distributionAmount);
        emit DistributionAmountUpdated(_distributionAmount);
    }

    /**
     * @notice Submits a batch of recipient addresses for future distribution.
     * @dev Only the owner can call this function.
     * @dev Skips addresses that are already submitted or have sufficient balance.
     * @param _recipients An array of recipient addresses.
     */
    function submitAddresses(address[] calldata _recipients) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_isAddressSubmitted(_recipients[i]) || _recipients[i].balance >= distributionAmount) {
                continue; // Skip already submitted addresses and addresses with sufficient balance
            }
            recipients.push(_recipients[i]);
        }
        console2.log("Addresses submitted: %d", recipients.length);
        emit AddressesSubmitted(recipients);
    }

    /**
     * @notice Distributes SepoliaETH to all submitted addresses.
     * @dev Only the owner can call this function.
     */
    function distributeBatch() external onlyOwner {
        // Checks
        if (address(this).balance < recipients.length * distributionAmount) {
            revert InsufficientContractBalance(recipients.length * distributionAmount, address(this).balance);
        }
        if (recipients.length == 0) {
            revert NoRecipients();
        }

        // Effects
        address[] memory currentRecipients = recipients;
        delete recipients;

        // Interactions
        for (uint256 i = 0; i < currentRecipients.length; i++) {
            (bool sent,) = currentRecipients[i].call{ value: distributionAmount }("");
            if (!sent) {
                emit TransferFailed(currentRecipients[i]);
            }
        }

        emit BatchDistributed(currentRecipients, distributionAmount);
        emit AddressesCleared();
    }

    /**
     * @notice Clears the recipients array.
     * @dev Only the owner can call this function.
     */
    function clearAddresses() public onlyOwner {
        delete recipients;
        emit AddressesCleared();
    }

    // return the list of recipients
    function getRecipients() public view returns (address[] memory) {
        return recipients;
    }

    /**
     * @notice Withdraws the contract balance to the owner.
     * @dev Transfers the contract balance to the owner's address using a low-level call.
     * Emits a Withdrawal event on successful transfer.
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert ContractBalanceZero();
        }

        // Attempt to transfer the contract balance to the owner using call
        (bool sent,) = msg.sender.call{ value: balance }("");
        console2.log("Withdrawal status: %s", sent ? "Success" : "Failed");

        if (!sent) {
            revert WithdrawalFailed();
        }

        emit Withdrawal(owner(), balance);
    }

    /**
     * @notice Fallback function to accept Ether deposits.
     */
    receive() external payable { }

    /**
     * @dev Checks if an address is already submitted.
     * @param _address The address to check.
     * @return bool indicating if the address is already submitted.
     */
    function _isAddressSubmitted(address _address) internal view returns (bool) {
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == _address) {
                return true;
            }
        }
        return false;
    }
}
