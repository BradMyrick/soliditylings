// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract ConstantVariables {
    uint256 public constant MAX_SUPPLY = 10000;

    function checkSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }
}

contract VariablesTest is Test {
    ConstantVariables constantVars;

    function setUp() public {
        constantVars = new ConstantVariables();
    }

    function testMaxSupply() public {
        assertEq(constantVars.MAX_SUPPLY(), 10000);
        assertEq(constantVars.checkSupply(), 10000);
    }
}
