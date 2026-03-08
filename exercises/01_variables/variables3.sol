// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";

// variables3.sol
// Make me compile and pass the test!

contract ConstantVariables {
    // TODO: Declare a constant public unsigned integer named `MAX_SUPPLY` and set it to 10000.
    // HINT: Use the `constant` keyword for values that never change.
    
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
