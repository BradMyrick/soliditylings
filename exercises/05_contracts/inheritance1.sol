// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// inheritance1.sol
// Make me compile!

contract Animal {
    function speak() public pure virtual returns (string memory) {
        return "...";
    }
}

// TODO: Make the `Dog` contract inherit from `Animal`.
contract Dog {
    // TODO: Override the `speak` function to return "Woof!".
    
}
