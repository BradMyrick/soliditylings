// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// errors1
// Since Solidity 0.8.4 you can revert with custom errors instead of
// require strings. They are cheaper (4-byte selector vs a full string in
// calldata and bytecode) and they carry typed data — an auditor can
// grep for exactly which failure fired.
//
//   error Unauthorized(address caller);
//   revert Unauthorized(msg.sender);
//
// TODO: 1. Define a custom error `Unauthorized` taking an `address caller`.
//       2. In `doSomethingRestricted`, revert with it when the caller
//          is not `owner`. The owner must sail through.

import "forge-std/Test.sol";

contract Errors1 {
    // TODO: define the `Unauthorized` error here

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function doSomethingRestricted() public {
        // TODO: revert if the caller is not the owner
    }
}

contract Errors1Test is Test {
    Errors1 target;

    function setUp() public {
        target = new Errors1();
    }

    function testOwnerSucceeds() public {
        // The test contract deployed it, so it is the owner.
        target.doSomethingRestricted(); // must not revert
    }

    function testStrangerReverts() public {
        vm.prank(address(0xDEAD));
        vm.expectRevert();
        target.doSomethingRestricted();
    }
}
