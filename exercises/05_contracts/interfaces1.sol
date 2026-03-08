// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// interfaces1.sol
// Make me compile!

// TODO: Define an interface named `IGreeter` with a single public pure
// function named `greet` that returns a `string memory`.


contract Greeter is IGreeter {
    function greet() public pure override returns (string memory) {
        return "Hello!";
    }
}

contract Caller {
    function callGreet(address target) public view returns (string memory) {
        // TODO: Cast `target` to `IGreeter` and call `greet()`.
        
    }
}
