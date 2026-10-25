// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// arithmetic1 — SECURITY
// Before Solidity 0.8, uint8 x = 255; x + 1; silently wrapped to 0 —
// the "integer overflow" bug class (beauty of 0.8: arithmetic on
// user input is CHECKED and reverts instead).
//
// But `unchecked { }` opts a block back into the old wrap-around
// behavior — with great power comes an audit finding. Here, a user
// can add loyalty points past the uint8 cap and wrap their balance
// to near-zero. The test catches the exploit; you close it.
//
// TODO: Make `add` revert on overflow instead of wrapping.
// Keep the zero-value and small-add behavior unchanged.

import "forge-std/Test.sol";

contract Loyalty {
    uint8 public points;

    function add(uint8 amount) external {
        unchecked {
            points += amount;
        }
    }
}

contract Arithmetic1Test is Test {
    Loyalty loyalty;

    function setUp() public {
        loyalty = new Loyalty();
    }

    function testSmallAdds() public {
        loyalty.add(200);
        loyalty.add(55);
        assertEq(loyalty.points(), 255, "255 must still be reachable");
    }

    function testOverflowReverts() public {
        loyalty.add(255);
        vm.expectRevert(); // 255 + 1 must NOT wrap to 0
        loyalty.add(1);
    }
}
