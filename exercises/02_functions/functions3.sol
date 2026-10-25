// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// functions3
// Mutability keywords are promises to the compiler:
//
//   pure  — "I will not even READ state"
//   view  — "I may read state, but never write it"
//   (none) — "I may write state"
//
// `getValue` is marked `pure`, yet it reads the state variable `value`.
// The compiler catches the lie. Reading state is allowed — writing is
// not — so one keyword up the ladder fixes this.
//
// TODO: Change the mutability so the function compiles and returns 42.

import "forge-std/Test.sol";

contract Functions3 {
    uint256 public value;

    constructor() {
        value = 42;
    }

    // TODO: fix the mutability keyword
    function getValue() public pure returns (uint256) {
        return value;
    }
}

contract Functions3Test is Test {
    Functions3 target;

    function setUp() public {
        target = new Functions3();
    }

    function testGetValue() public {
        assertEq(target.getValue(), 42);
    }
}
