// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// payments2 — never trust exact balance
// Your accounting says "we hold 5 ETH, users own 5 ETH" — but anyone
// can FORCE ETH into a contract: plain transfers, vm.deal in tests,
// and (pre-Cancun) selfdestruct. EIP-6780 tamed selfdestruct in 2024,
// but donation paths never close. If your code asserts
// `balance == accounted`, a single donor takes the contract down.
//
// The audited pattern: use `>=` accounting — donations are a SURPLUS,
// not an error. (This is exactly the `sweepable excess` idea from
// ownership4, from the safety side.)
//
// TODO: Fix `solvent` — it must return true whenever the contract
// holds AT LEAST what it owes users. A generous donor must never be
// able to make a solvent contract look insolvent.

import "forge-std/Test.sol";

contract Bank {
    uint256 public totalOwed; // aggregate user claims

    function deposit() external payable {
        totalOwed += msg.value;
    }

    // BROKEN: exact equality — one forced donation bricks it
    function solvent() external view returns (bool) {
        return address(this).balance == totalOwed;
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
        // A benefactor force-feeds the bank 3 ETH out of kindness.
        vm.deal(address(bank), 8 ether);

        // The bank still owes exactly 5 and holds 8 — it is MORE than
        // solvent. Exact-equality accounting would disagree and brick.
        assertTrue(bank.solvent(), "surplus must not read as insolvency");
        assertEq(address(bank).balance, 8 ether);
    }
}
