// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// functions3.sol
// Make me compile!

contract Functions3 {
    uint256 public value;

    // TODO: This function attempts to read a state variable, but the compiler complains.
    // What state mutability modifier should be used here instead of `pure`?
    function getValue() public pure returns (uint256) {
        return value;
    }
}
