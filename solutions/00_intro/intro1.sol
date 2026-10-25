// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Intro1 {
    uint256 public welcome;
}

contract Intro1Test is Test {
    function testWelcome() public {
        Intro1 intro = new Intro1();
        assertTrue(address(intro) != address(0));
    }
}
