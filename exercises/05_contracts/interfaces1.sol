// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// interfaces1
// An interface is a contract skeleton: function signatures with no
// bodies. Functions in an interface are implicitly `external` — no
// visibility keyword needed (or allowed, beyond external).
//
// Calling another contract means casting its address to the interface
// and calling through it. The EVM verifies nothing at runtime — if the
// target doesn't actually implement the function, the call reverts.
//
// TODO: 1. Define an interface `IGreeter` declaring `greet()` — a pure
//          view of the world returning a `string memory`.
//       2. In `Caller.callGreet`, cast `target` to `IGreeter` and
//          return its greeting.

import "forge-std/Test.sol";

// TODO: define the `IGreeter` interface here


contract Greeter is IGreeter {
    function greet() external pure returns (string memory) {
        return "Hello!";
    }
}

contract Caller {
    function callGreet(address target) external view returns (string memory) {
        // TODO: call greet() on `target` through the interface
    }
}

contract Interfaces1Test is Test {
    Caller caller;
    Greeter greeter;

    function setUp() public {
        caller = new Caller();
        greeter = new Greeter();
    }

    function testCallThroughInterface() public {
        assertEq(caller.callGreet(address(greeter)), "Hello!");
    }
}
