// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

// reentrancy1.sol
// Security!

contract Vault {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // TODO: This function is vulnerable to reentrancy!
    // Fix it by applying the checks-effects-interactions pattern.
    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        balances[msg.sender] = 0;
    }
}

contract Attacker {
    Vault public vault;

    constructor(Vault _vault) {
        vault = _vault;
    }

    function attack() public payable {
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether) {
            vault.withdraw();
        }
    }
}

contract Reentrancy1Test is Test {
    Vault vault;
    Attacker attacker;

    function setUp() public {
        vault = new Vault();
        // Give the vault some initial funds so there is something to steal
        vm.deal(address(this), 10 ether);
        vault.deposit{value: 10 ether}();

        attacker = new Attacker(vault);
    }

    function testReentrancy() public {
        vm.deal(address(attacker), 1 ether);
        
        // This attack shouldn't be able to drain the vault if the vulnerability is fixed!
        // We expect it to revert (since the re-entrant call will fail or balances are 0).
        vm.expectRevert();
        attacker.attack{value: 1 ether}();

        // The vault should still have its original 10 ether, plus whatever the attacker deposited and withdrew normally
        // Actually if it reverts the attacker's balance remains 1 ether, and the vault stays at 10 ether.
        assertEq(address(vault).balance, 10 ether);
    }
}
