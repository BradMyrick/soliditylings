// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Modifiers1 {
    address public owner;
    bool public changed;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function changeState() public onlyOwner {
        changed = true;
    }
}

contract Modifiers1Test is Test {
    Modifiers1 mod;

    function setUp() public {
        mod = new Modifiers1();
    }

    function testOwnerCanChange() public {
        mod.changeState();
        assertTrue(mod.changed());
    }

    function testOtherCannotChange() public {
        vm.prank(address(0xdead));
        vm.expectRevert();
        mod.changeState();
    }
}
