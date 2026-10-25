// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// arithmetic3
// Solidity NEVER converts numeric types implicitly — every narrowing
// is an explicit cast, and casting to a SMALLER type truncates: it
// keeps the low bits and throws the rest away.
//
//   uint8(uint256(0x01FF)) == 0xFF   // the high byte is simply lost
//   uint256(int8(-1))       == 0xFF..FF (2^256-1) — sign extends!
//
// Auditors grep for every explicit cast touching user input.
//
// TODO: Implement `lowByte` so it returns ONLY the lowest byte of
// `value` (cast down), and `toUint` so it losslessly converts an
// amount that is guaranteed <= 2^128-1 (cast up).

import "forge-std/Test.sol";

contract Casts {
    // TODO: return the lowest 8 bits of `value`
    function lowByte(uint256 value) external pure returns (uint8) {
        return 0; // REPLACE ME
    }

    // TODO: widen `amount` into a uint256 without losing information
    function toUint(uint128 amount) external pure returns (uint256) {
        return 0; // REPLACE ME
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
