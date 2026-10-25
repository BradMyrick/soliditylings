// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Dispatcher {
    error UnknownCall(bytes data);

    uint256 public receivedCount;

    // Every call that matches no declared function lands here —
    // revert LOUDLY with the raw calldata for the runbook.
    fallback() external payable {
        revert UnknownCall(msg.data);
    }

    receive() external payable {
        receivedCount += 1;
    }
}

contract Payments3Test is Test {
    Dispatcher target;

    function setUp() public {
        target = new Dispatcher();
    }

    function testPlainTransferHitsReceive() public {
        (bool ok,) = address(target).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(target.receivedCount(), 1);
        assertEq(address(target).balance, 1 ether);
    }

    function testGarbageSelectorRevertsLoudly() public {
        bytes memory garbage = abi.encodeWithSignature("definitelyNotAFunction()");

        (bool ok, bytes memory ret) = address(target).call(garbage);
        assertFalse(ok, "must revert");
        bytes4 gotSelector;
        assembly {
            gotSelector := mload(add(ret, 32))
        }
        assertEq(gotSelector, Dispatcher.UnknownCall.selector, "UnknownCall(bytes)");
    }

    function testGarbageWithValueAlsoReverts() public {
        (bool ok,) = address(target).call{value: 1 ether}(abi.encodePacked("0xdeadbeef"));
        assertFalse(ok);
        assertEq(target.receivedCount(), 0, "receive must not catch data calls");
    }
}
