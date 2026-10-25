// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Bank {
    uint256 public totalOwed;

    function deposit() external payable {
        totalOwed += msg.value;
    }

    // FIXED: solvency is a FLOOR, not an exact figure — donations are
    // surplus, never a brick.
    function solvent() external view returns (bool) {
        return address(this).balance >= totalOwed;
    }

    receive() external payable {}
}

contract Payments2Test is Test {
    Bank bank;

    function setUp() public {
        bank = new Bank();
        bank.deposit{value: 5 ether}();
    }

    function testSolventWhenExact() public {
        assertTrue(bank.solvent(), "1:1 deposits must be solvent");
    }

    function testForcedEthDoesNotBrick() public {
        vm.deal(address(bank), 8 ether);

        assertTrue(bank.solvent(), "surplus must not read as insolvency");
        assertEq(address(bank).balance, 8 ether);
    }

    receive() external payable {}
}
