// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Enums1 {
    enum State {
        Pending,
        Active,
        Inactive
    }

    State public currentState;

    function activate() public {
        currentState = State.Active;
    }
}

contract Enums1Test is Test {
    Enums1 target;

    function setUp() public {
        target = new Enums1();
    }

    function testActivate() public {
        assertEq(uint8(target.currentState()), 0, "starts at Pending");

        target.activate();
        assertEq(uint8(target.currentState()), 1, "Active is the second member");
        assertTrue(target.currentState() == Enums1.State.Active);
    }
}
