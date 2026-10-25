// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// variables3
// Some values are known at compile time and never change. For those,
// Solidity has `constant` — the compiler inlines the value directly into
// the bytecode instead of paying for a storage slot read.
//
// As a rule of thumb: if you can compute it at compile time and it never
// changes, reach for `constant`. (If it's set once at deploy time from a
// constructor argument, that's `immutable` — a later exercise.)
//
// TODO: Declare MAX_SUPPLY as a public uint256 that is constant and
// equals 10000.

import "forge-std/Test.sol";

contract ConstantVariables {
    // TODO: declare MAX_SUPPLY here

    function checkSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }
}

contract VariablesTest is Test {
    ConstantVariables constantVars;

    function setUp() public {
        constantVars = new ConstantVariables();
    }

    function testMaxSupply() public {
        assertEq(constantVars.MAX_SUPPLY(), 10000);
        assertEq(constantVars.checkSupply(), 10000);
    }
}
