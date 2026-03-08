// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";

// modifiers1.sol
// Make me compile and pass the test!

contract Modifiers1 {
    address public owner;
    bool public changed;

    constructor() {
        owner = msg.sender;
    }

    // TODO: Write a modifier named `onlyOwner` that reverts
    // if `msg.sender` is not the `owner`. Use a standard `require`.
    

    // TODO: Apply your modifier to this function.
    function changeState() public {
        changed = true;
    }
}

contract Modifiers1Test is Test {
    Modifiers1 mod;

    function setUp() public {
        mod = new Modifiers1(); // Deployer is the test contract
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
