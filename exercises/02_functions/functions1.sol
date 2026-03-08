// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";

// functions1.sol
// Make me compile and pass the test!

contract Functions1 {
    // TODO: Write a function named `sayHello` that:
    // 1. Is public
    // 2. Returns a string memory
    // 3. Does not modify state (pure)
    // 4. Returns exactly "Hello, world!"
    
}

contract Functions1Test is Test {
    Functions1 funcs;

    function setUp() public {
        funcs = new Functions1();
    }

    function testSayHello() public {
        assertEq(funcs.sayHello(), "Hello, world!");
    }
}
