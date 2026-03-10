// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// memory1.sol
// Make me compile!

contract Memory1 {
    // TODO: Fix the compile error by specifying the data location of the argument
    function sayHello(string greeting) public pure returns (string memory) {
        return greeting;
    }
}
