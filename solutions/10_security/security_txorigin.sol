// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Wallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "not authorized"); // FIXED: direct caller
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}

contract Attacker {
    Wallet public wallet;

    constructor(Wallet w) {
        wallet = Wallet(w);
    }

    function attack(uint256 amount) external {
        wallet.withdraw(amount);
    }
}

contract TxOriginTest is Test {
    Wallet wallet;
    Attacker attacker;

    function setUp() public {
        wallet = new Wallet();
        vm.deal(address(wallet), 10 ether);
        attacker = new Attacker(wallet);
    }

    function testAttackReverts() public {
        vm.expectRevert();
        attacker.attack(1 ether);
        assertEq(address(wallet).balance, 10 ether, "no funds moved");
    }

    function testOwnerDirectCallStillWorks() public {
        wallet.withdraw(1 ether);
        assertEq(address(wallet).balance, 9 ether);
    }

    receive() external payable {}
}
