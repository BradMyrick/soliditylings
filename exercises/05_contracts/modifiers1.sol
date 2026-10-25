// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// modifiers1
// A modifier wraps a function with reusable pre/post logic. The `_;`
// placeholder marks where the decorated function's body runs.
//
//   modifier onlyOwner() {
//       require(msg.sender == owner, "Not owner");
//       _;
//   }
//
// Modifiers are how access control is expressed idiomatically.
//
// TODO: 1. Write a modifier `onlyOwner` that reverts if the caller is
//          not `owner`.
//       2. Apply it to `changeState`.

import "forge-std/Test.sol";

contract Modifiers1 {
    address public owner;
    bool public changed;

    constructor() {
        owner = msg.sender;
    }

    // TODO: write the `onlyOwner` modifier


    // TODO: apply your modifier to this function
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
