// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Memory1 {
    function sayHello(string memory greeting) public pure returns (string memory) {
        return greeting;
    }
}

contract Memory1Test is Test {
    Memory1 target;

    function setUp() public {
        target = new Memory1();
    }

    function testSayHello() public {
        assertEq(target.sayHello("hi"), "hi");
    }
}
