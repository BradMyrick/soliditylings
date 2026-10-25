// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Casts {
    function lowByte(uint256 value) external pure returns (uint8) {
        return uint8(value); // explicit truncation: low 8 bits
    }

    function toUint(uint128 amount) external pure returns (uint256) {
        return uint256(amount); // widening is always lossless
    }
}

contract Arithmetic3Test is Test {
    Casts casts;

    function setUp() public {
        casts = new Casts();
    }

    function testLowByteTruncates() public {
        assertEq(casts.lowByte(0x01FF), 0xFF, "high bits are dropped");
        assertEq(casts.lowByte(256 + 7), 7);
        assertEq(casts.lowByte(type(uint8).max), type(uint8).max);
    }

    function testWideningIsLossless() public {
        assertEq(casts.toUint(type(uint128).max), type(uint128).max);
        assertEq(casts.toUint(1), 1);
    }
}
