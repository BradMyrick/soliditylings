// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// mappings2
// Mappings compose: the value of a mapping can itself be a mapping.
// This is exactly how ERC-20 approvals work —
// `allowance[owner][spender] = amount`.
//
// TODO: 1. Declare a public nested mapping: address => address => uint256,
//          named `allowance`.
//       2. In `getAllowance`, read the amount `owner` granted `spender`.
//          The `return 0` placeholder must go.

import "forge-std/Test.sol";

contract NestedMappings {
    // TODO: declare `allowance` here

    function getAllowance(address owner, address spender) public view returns (uint256) {
        // TODO: return the allowance for this (owner, spender) pair
        return 0; // REPLACE ME
    }
}

contract Mappings2Test is Test {
    NestedMappings target;

    function setUp() public {
        target = new NestedMappings();
    }

    function testNestedRead() public {
        // The public getter works on nested mappings too — it just takes
        // both keys in order.
        assertEq(target.allowance(address(1), address(2)), 0, "unset pair is 0");
        assertTrue(target.getAllowance(address(1), address(2)) == target.allowance(address(1), address(2)));
    }
}
