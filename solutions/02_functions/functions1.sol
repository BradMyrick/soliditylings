// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Functions1 {
    function sayHello() public pure returns (string memory) {
        return "Hello, world!";
    }
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
