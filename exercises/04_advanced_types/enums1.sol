// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// enums1
// An enum is a uint8 under the hood with named members — a cheap way to
// model a state machine. Members count up from 0, and the type converts
// explicitly to/from uint8. Perfect for escrow-style states.
//
// TODO: 1. Define an enum named `State` with members Pending, Active,
//          Inactive (in that order — the order defines the numbers).
//       2. In `activate`, set `currentState` to the Active member.

import "forge-std/Test.sol";

contract Enums1 {
    // TODO: define the `State` enum here

    State public currentState; // starts at the first member: Pending

    function activate() public {
        // TODO: set the state to Active
    }
}

contract Enums1Test is Test {
    Enums1 target;

    function setUp() public {
        target = new Enums1();
    }

    function testActivate() public {
        // Before: the zero value of an enum is its first member.
        assertEq(uint8(target.currentState()), 0, "starts at Pending");

        target.activate();
        assertEq(uint8(target.currentState()), 1, "Active is the second member");
        assertTrue(target.currentState() == Enums1.State.Active);
    }
}
