// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// functions2.sol
// Make me compile!

contract Functions2 {
    uint256 public counter;

    // TODO: What visibility modifier should this function have so that
    // anyone can call it from outside the contract?
    function increment() {
        counter += 1;
    }
}
