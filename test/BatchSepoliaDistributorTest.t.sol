// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";

import { BatchSepoliaDistributor } from "../src/BatchSepoliaDistributor.sol";

contract BatchSepoliaDistributorTest is Test {
    // Vm public constant vm = Vm(HEVM_ADDRESS);s

    BatchSepoliaDistributor distributor;
    address owner;
    address[] recipients;

    function setUp() public {
        owner = address(this);
        distributor = new BatchSepoliaDistributor(0.1 ether);

        // Add a list of recipient addresses
        recipients = new address[](3);
        recipients[0] = address(1);
        recipients[1] = address(2);
        recipients[2] = address(3);
    }

    function testSetDistributionAmount() public {
        distributor.setDistributionAmount(0.2 ether);
        assertEq(distributor.distributionAmount(), 0.2 ether);
    }

    function testSubmitAddresses() public {
        distributor.submitAddresses(recipients);

        address[] memory submittedRecipients = distributor.getRecipients();
        assertEq(submittedRecipients.length, recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            assertEq(submittedRecipients[i], recipients[i]);
        }
    }

    function testDistributeBatch() public {
        distributor.submitAddresses(recipients);

        // Fund the contract with enough Ether for distribution
        vm.deal(address(distributor), 0.5 ether);

        distributor.distributeBatch();

        // Check that recipients received the distribution amount
        for (uint256 i = 0; i < recipients.length; i++) {
            assertEq(recipients[i].balance, 0.1 ether);
        }

        // Check that the recipients array is cleared after distribution
        address[] memory submittedRecipients = distributor.getRecipients();
        assertEq(submittedRecipients.length, 0);
    }

    // test distribute batch without recipients
    function testDistributeBatchNoRecipients() public {
        vm.expectRevert(abi.encodeWithSelector(BatchSepoliaDistributor.NoRecipients.selector));
        distributor.distributeBatch();
    }

    function testInsufficientContractBalance() public {
        distributor.submitAddresses(recipients);

        // Fund the contract with insufficient Ether
        vm.deal(address(distributor), 0.1 ether);

        vm.expectRevert(
            abi.encodeWithSelector(BatchSepoliaDistributor.InsufficientContractBalance.selector, 0.3 ether, 0.1 ether)
        );
        distributor.distributeBatch();
    }

    function testSubmitDuplicateAddress() public {
        address[] memory dupRecipients = new address[](4);
        dupRecipients[0] = address(1);
        dupRecipients[1] = address(2);
        dupRecipients[2] = address(1); // Duplicate
        dupRecipients[3] = address(3);

        distributor.submitAddresses(dupRecipients);

        address[] memory submittedRecipients = distributor.getRecipients();
        // Duplicate address should not be added twice
        assertEq(submittedRecipients.length, 3);
    }

    // test submit address with sufficient balance
    function testSubmitAddressWithSufficientBalance() public {
        address[] memory sufficientRecipients = new address[](3);
        sufficientRecipients[0] = address(1);
        sufficientRecipients[1] = address(2);
        sufficientRecipients[2] = address(3);

        vm.deal(sufficientRecipients[1], 0.5 ether);
        distributor.submitAddresses(sufficientRecipients);
        address[] memory submittedRecipients = distributor.getRecipients();
        // Addresses with sufficient balance should not be added
        assertEq(submittedRecipients.length, 2);
    }

    function testClearAddresses() public {
        distributor.submitAddresses(recipients);
        distributor.clearAddresses();

        address[] memory submittedRecipients = distributor.getRecipients();
        assertEq(submittedRecipients.length, 0);
    }

    function testFundContract() public {
        // Fund the contract with Ether additional to the distribution amount
        vm.deal(address(distributor), 1 ether);
        assertEq(address(distributor).balance, 1 ether);
    }

    // test withdraw contract balance
    function testWithdrawContractBalance() public {
        // Fund the contract with Ether additional to the distribution amount
        vm.deal(address(distributor), 1 ether);
        assertEq(address(distributor).balance, 1 ether);
        distributor.withdraw();
        assertEq(address(distributor).balance, 0);
    }

    // fallback function to receive Ether
    receive() external payable { }
    
}
