// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Vault {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // checks-effects-interactions: zero the balance BEFORE the call,
    // so a re-entrant withdraw sees nothing left to take.
    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        balances[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
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
        if (address(vault).balance >= 1 ether) {
            vault.withdraw();
        }
    }
}

contract Reentrancy1Test is Test {
    Vault vault;
    Attacker attacker;

    receive() external payable {}

    function setUp() public {
        vault = new Vault();
        vm.deal(address(this), 11 ether);

        vault.deposit{value: 10 ether}();

        attacker = new Attacker(vault);
        vm.deal(address(attacker), 1 ether);
    }

    function testAttackReverts() public {
        vm.expectRevert();
        attacker.attack{value: 1 ether}();

        assertEq(address(vault).balance, 10 ether, "vault must keep its funds");
        assertEq(address(attacker).balance, 1 ether, "attacker keeps only its own ETH");
    }

    function testHonestWithdrawStillWorks() public {
        vault.withdraw();
        assertEq(address(vault).balance, 0);
        assertEq(address(this).balance, 11 ether);
    }
}
