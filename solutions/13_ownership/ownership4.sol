// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Sweepable {
    address public owner;
    uint256 public totalDeposits;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function depositFor(address user) external payable {
        require(msg.value > 0, "empty");
        totalDeposits += msg.value;
    }

    // FIXED: sweeps only the protocol's OWN excess — user deposits are
    // mathematically out of reach.
    function sweep(address to) external onlyOwner {
        uint256 excess = address(this).balance - totalDeposits;
        require(excess > 0, "nothing to sweep");
        payable(to).transfer(excess);
    }

    receive() external payable {}
}

contract Ownership4Test is Test {
    Sweepable vault;
    address ops = address(0x0F5);

    function setUp() public {
        vault = new Sweepable();
        vm.deal(ops, 0);
    }

    function testUsersMoneyIsUntouchable() public {
        vault.depositFor{value: 5 ether}(address(0xA));

        vm.expectRevert();
        vault.sweep(ops);

        assertEq(address(vault).balance, 5 ether, "not a wei moves");
    }

    function testExcessIsSweepable() public {
        vault.depositFor{value: 5 ether}(address(0xA));

        vm.deal(address(this), 3 ether);
        (bool ok,) = address(vault).call{value: 3 ether}("");
        assertTrue(ok);

        vault.sweep(ops);

        assertEq(address(ops).balance, 3 ether, "ops gets the excess");
        assertEq(address(vault).balance, 5 ether, "user deposits remain");
    }

    function testStrangerCannotSweep() public {
        vm.prank(address(0xBA0BAD));
        vm.expectRevert();
        vault.sweep(address(0xBA0BAD));
    }

    receive() external payable {}
}
