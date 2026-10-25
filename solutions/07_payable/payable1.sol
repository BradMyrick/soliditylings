// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Payable1 {
    function deposit() public payable {}
}

contract Payable1Test is Test {
    Payable1 target;

    function setUp() public {
        target = new Payable1();
    }

    function testDeposit() public {
        (bool success,) = address(target).call{value: 1 ether}(abi.encodeWithSignature("deposit()"));
        assertTrue(success, "Sending ETH should succeed");
        assertEq(address(target).balance, 1 ether);
    }
}
