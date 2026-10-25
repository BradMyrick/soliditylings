// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// reentrancy1 — SECURITY
// The classic. `withdraw` sends ETH to the caller BEFORE zeroing their
// balance (interaction before effects). A malicious contract's receive
// hook re-enters `withdraw` while the balance is still nonzero and
// drains the vault. This bug emptied The DAO in 2016 and forked Ethereum.
//
// The fix is the checks-effects-interactions pattern:
//   1. CHECKS    — validate the caller's balance
//   2. EFFECTS   — update your state FIRST
//   3. INTERACTIONS — then, and only then, touch external addresses
//
// TODO: Reorder `withdraw` so no re-entrant call can see stale state.
// The Attacker contract below will keep trying — make sure it fails.

import "forge-std/Test.sol";

contract Vault {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // TODO: apply checks-effects-interactions
    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        balances[msg.sender] = 0;
    }
}

contract Attacker {
    Vault public vault;

    constructor(Vault _vault) {
        vault = _vault;
    }

    function attack() external payable {
        vault.deposit{value: 1 ether}();
        vault.withdraw();
    }

    receive() external payable {
        // Re-enter as long as there is anything left to steal.
        if (address(vault).balance >= 1 ether) {
            vault.withdraw();
        }
    }
}

contract Reentrancy1Test is Test {
    Vault vault;
    Attacker attacker;

    // The vault pays out with a raw call — to receive ETH that way, a
    // contract needs a receive function. (Test contracts are contracts!)
    receive() external payable {}

    function setUp() public {
        vault = new Vault();
        vm.deal(address(this), 11 ether);

        // An honest deposit funds the vault.
        vault.deposit{value: 10 ether}();

        attacker = new Attacker(vault);
        vm.deal(address(attacker), 1 ether);
    }

    function testAttackReverts() public {
        // With CEI applied, the re-entrant withdraw inside receive()
        // finds a zeroed balance and reverts — which reverts the whole
        // attack transaction.
        vm.expectRevert();
        attacker.attack{value: 1 ether}();

        // Nothing was stolen: the vault is intact and the attacker's
        // ETH came back with the revert.
        assertEq(address(vault).balance, 10 ether, "vault must keep its funds");
        assertEq(address(attacker).balance, 1 ether, "attacker keeps only its own ETH");
    }

    function testHonestWithdrawStillWorks() public {
        // Fixing the bug must not break the feature.
        vault.withdraw();
        assertEq(address(vault).balance, 0);
        assertEq(address(this).balance, 11 ether);
    }
}
