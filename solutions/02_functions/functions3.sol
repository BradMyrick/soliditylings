// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Functions3 {
    uint256 public value;

    constructor() {
        value = 42;
    }

    function getValue() public view returns (uint256) {
        return value;
    }
}

contract Functions3Test is Test {
    Functions3 target;

    function setUp() public {
        target = new Functions3();
    }

    function testGetValue() public {
        assertEq(target.getValue(), 42);
    }
}
