// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Summer {
    function sumTo(uint8 n) external pure returns (uint256 total) {
        uint256 acc = 0; // wide accumulator — cannot overflow mid-loop
        for (uint256 i = 1; i <= n; i++) {
            acc += i;
        }
        return acc;
    }
}

contract Arithmetic2Test is Test {
    Summer summer;

    function setUp() public {
        summer = new Summer();
    }

    function testSmallSum() public {
        assertEq(summer.sumTo(10), 55);
    }

    function testFullRangeNoOverflow() public {
        assertEq(summer.sumTo(255), 32640);
    }
}
