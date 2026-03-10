// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

// payable1.sol
// Make me pass!

contract Payable1 {
    // TODO: We want to accept ETH when someone calls this function!
    // But it's missing something.
    function deposit() public {
        // Accept ETH
    }
}

contract Payable1Test is Test {
    Payable1 target;

    function setUp() public {
        target = new Payable1();
    }

    function testDeposit() public {
        // This will fail if the function is not payable
        (bool success, ) = address(target).call{value: 1 ether}(abi.encodeWithSignature("deposit()"));
        assertTrue(success, "Sending ETH should succeed");
        assertEq(address(target).balance, 1 ether);
    }
}
