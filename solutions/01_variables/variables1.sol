// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Variables1 {
    uint256 public myNumber;

    function getNumber() public view returns (uint256) {
        return myNumber;
    }
}

contract Variables1Test is Test {
    Variables1 vars;

    function setUp() public {
        vars = new Variables1();
    }

    function testZeroValue() public {
        assertEq(vars.myNumber(), 0, "uint256 zero value should be 0");
        assertEq(vars.getNumber(), 0);
    }
}
