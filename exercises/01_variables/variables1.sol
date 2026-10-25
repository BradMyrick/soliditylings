// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// variables1
// State variables live in storage, on the blockchain itself.
//
// Unlike Go or Rust, Solidity has no `null` — every type has a "zero
// value" (uint256's is 0, address's is 0x0, bool's is false) and an
// uninitialized variable simply starts there.
//
// TODO: Declare a PUBLIC state variable named `myNumber` of type `uint256`.
// Do not initialize it — let the zero value do the work.

import "forge-std/Test.sol";

contract Variables1 {
    // TODO: declare `myNumber` here

    function getNumber() public view returns (uint256) {
        return myNumber;
    }
}

contract Variables1Test is Test {
    Variables1 vars;

    function setUp() public {
        vars = new Variables1();
    }

    function testZeroValue() public {
        // A declared-but-uninitialized uint256 reads as 0.
        assertEq(vars.myNumber(), 0, "uint256 zero value should be 0");
        assertEq(vars.getNumber(), 0);
    }
}

// touch
