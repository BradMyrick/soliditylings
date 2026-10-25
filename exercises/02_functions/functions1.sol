// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// functions1
// A Solidity function declaration reads inside-out:
//
//   function name(params) <visibility> <mutability> returns (Type)
//
// Visibility says WHO can call it; mutability says WHAT it may do.
// `pure` is the strictest mutability: no reading state, no writing state.
//
// TODO: Write a function named `sayHello` that is public, pure,
// returns a `string memory`, and returns exactly "Hello, world!".

import "forge-std/Test.sol";

contract Functions1 {
    // TODO: write `sayHello` here

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
