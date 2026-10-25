// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Arrays1 {
    uint256[] public numbers;

    function addNumber(uint256 number) public {
        numbers.push(number);
    }

    function count() public view returns (uint256) {
        return numbers.length;
    }
}

contract Arrays1Test is Test {
    Arrays1 target;

    function setUp() public {
        target = new Arrays1();
    }

    function testPush() public {
        target.addNumber(7);
        target.addNumber(42);
        assertEq(target.numbers(0), 7, "first element");
        assertEq(target.numbers(1), 42, "second element");
        assertEq(target.count(), 2, "length after two pushes");
    }
}
