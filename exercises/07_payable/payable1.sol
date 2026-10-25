// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// payable1
// `payable` is a type modifier for both functions and addresses. A
// function marked payable may receive ETH with the call; without the
// keyword, any attached value reverts before your code even runs.
//
// Note how `payable` composes with the other keywords you've met:
// visibility (public) comes first, then mutability.
//
// TODO: Make `deposit` able to receive ETH.

import "forge-std/Test.sol";

contract Payable1 {
    // TODO: accept ETH here
    function deposit() public {
        // No body needed — receiving the ETH is the point.
    }
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
