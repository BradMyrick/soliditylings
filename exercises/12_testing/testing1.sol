// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// testing1 — revert assertions
// The contract below is CORRECT. Your job is to finish its test suite —
// because in this curriculum (and in every audit), proving the bad
// path reverts is as important as proving the happy path works.
//
// Precise revert assertions beat generic ones:
//
//   vm.expectRevert();                          // anything reverts — weak
//   vm.expectRevert(Vault.Insufficient.selector); // THIS error — strong
//
// TODO: Complete the two tests. Assert the custom error (by selector)
// for the underflow case, and the string for the zero case.

import "forge-std/Test.sol";

contract Vault {
    error Insufficient(uint256 requested, uint256 available);
    error ZeroAmount();

    mapping(address => uint256) public balances;

    function deposit() external payable {
        require(msg.value > 0, "empty deposit");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        uint256 avail = balances[msg.sender];
        if (amount > avail) revert Insufficient(amount, avail);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}

contract Testing1Test is Test {
    Vault vault;

    function setUp() public {
        vault = new Vault();
    }

    function testWithdrawMoreThanBalance() public {
        vault.deposit{value: 1 ether}();

        // TODO: assert the Insufficient error reverts — with its args
        // (requested, available) encoded, forge matches it exactly:
        // vm.expectRevert(abi.encodeWithSelector(...selector, 2 ether, 1 ether))
        vault.withdraw(2 ether);

        fail("unreachable if you asserted the revert above");
    }

    function testWithdrawZero() public {
        // TODO: assert the ZeroAmount error reverts
        vault.withdraw(0);

        fail("unreachable if you asserted the revert above");
    }
}
