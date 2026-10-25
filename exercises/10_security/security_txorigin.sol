// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// security_txorigin — AUDIT FINDING: "tx.origin authentication"
// `tx.origin` is the EOA that STARTED the transaction chain;
// `msg.sender` is the immediate caller. Authenticating with tx.origin
// means: if an owner ever calls ANY attacker contract, that contract
// can call THIS wallet "as" the owner mid-chain. That's phishing with
// on-chain consequences — EIP-3074/7702 make it worse, not better.
//
// Rule: authenticate with msg.sender, never tx.origin.
//
// TODO: Fix `withdraw` to authenticate the DIRECT caller.
//
// The Attacker contract below is the exploit path: the owner (here,
// the test contract) merely calls attack() once, and the attacker
// slips a withdraw() in behind it. Your fix must make that revert.

import "forge-std/Test.sol";

contract Wallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function withdraw(uint256 amount) external {
        require(tx.origin == owner, "not authorized"); // VULNERABLE
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}

contract Attacker {
    Wallet public wallet;

    constructor(Wallet w) {
        wallet = Wallet(w);
    }

    // Owner calls this (tx.origin == owner), we call withdraw in the
    // same chain: tx.origin is still the owner, msg.sender is us.
    function attack(uint256 amount) external {
        wallet.withdraw(amount);
    }
}

contract TxOriginTest is Test {
    Wallet wallet;
    Attacker attacker;

    function setUp() public {
        wallet = new Wallet(); // test contract = owner + tx.origin
        vm.deal(address(wallet), 10 ether);
        attacker = new Attacker(wallet);
    }

    function testAttackReverts() public {
        vm.expectRevert(); // the mid-chain call must fail your check
        attacker.attack(1 ether);
        assertEq(address(wallet).balance, 10 ether, "no funds moved");
    }

    function testOwnerDirectCallStillWorks() public {
        wallet.withdraw(1 ether);
        assertEq(address(wallet).balance, 9 ether);
    }

    receive() external payable {}
}
