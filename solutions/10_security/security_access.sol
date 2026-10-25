// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract TipJar {
    address public owner;
    address public treasury;

    constructor() {
        owner = msg.sender;
        treasury = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // FIXED: open to everyone — tips are tips.
    function deposit() external payable {}

    // FIXED: owner-only — where the money goes.
    function setTreasury(address t) external onlyOwner {
        treasury = t;
    }

    receive() external payable {}
}

contract AccessTest is Test {
    TipJar jar;

    function setUp() public {
        jar = new TipJar();
    }

    function testAnyoneCanDeposit() public {
        vm.deal(address(0xBEEF), 1 ether);
        vm.prank(address(0xBEEF));
        jar.deposit{value: 1 ether}();
        assertEq(address(jar).balance, 1 ether);
    }

    function testOnlyOwnerSetsTreasury() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        jar.setTreasury(address(0xBEEF));

        jar.setTreasury(address(0x1234));
        assertEq(jar.treasury(), address(0x1234));
    }
}
