// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Loyalty {
    uint8 public points;

    function add(uint8 amount) external {
        points += amount; // checked math: overflow reverts
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
        vm.expectRevert();
        loyalty.add(1);
    }
}
