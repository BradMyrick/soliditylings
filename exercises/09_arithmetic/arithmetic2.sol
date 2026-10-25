// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// arithmetic2
// Checked math is a safety net, not a design. When a computation can
// legitimately exceed a narrow type's range, the fix is to compute in a
// WIDER type — not to sprinkle `unchecked` around.
//
// Summing uint8 values into a uint8 accumulator overflows as soon as
// the running total passes 255, even though every input fits.
//
// TODO: Make `sumTo` compute the correct total for any n up to 255.
// The return type is already uint256 — pick an accumulator type that
// can't overflow halfway through the loop.

import "forge-std/Test.sol";

contract Summer {
    function sumTo(uint8 n) external pure returns (uint256 total) {
        uint8 acc = 0; // TODO: this accumulator is one byte wide
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
        // 1+2+...+255 = 32640 — fits uint256 easily, overflows uint8
        // partway through. The whole range must work without reverting.
        assertEq(summer.sumTo(255), 32640);
    }
}
