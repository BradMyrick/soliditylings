// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract NestedMappings {
    mapping(address => mapping(address => uint256)) public allowance;

    function getAllowance(address owner, address spender) public view returns (uint256) {
        return allowance[owner][spender];
    }
}

contract Mappings2Test is Test {
    NestedMappings target;

    function setUp() public {
        target = new NestedMappings();
    }

    function testNestedRead() public {
        assertEq(target.allowance(address(1), address(2)), 0, "unset pair is 0");
        assertTrue(target.getAllowance(address(1), address(2)) == target.allowance(address(1), address(2)));
    }
}
