// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Receive1 {
    uint256 public counter;

    receive() external payable {
        counter += 1;
    }
}

contract Receive1Test is Test {
    Receive1 target;

    function setUp() public {
        target = new Receive1();
    }

    function testReceive() public {
        (bool success,) = address(target).call{value: 1 ether}("");
        assertTrue(success, "The contract should accept plain ETH");
        assertEq(address(target).balance, 1 ether);
        assertEq(target.counter(), 1, "receive should have run once");
    }
}
