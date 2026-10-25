// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// payments3 — receive vs fallback dispatch
// The two special functions form a decision tree for incoming calls:
//
//   calldata empty   → receive()  (if it exists)
//   calldata unknown → fallback() (if it exists)
//   neither matches  → revert
//
// A missing fallback means random selectors revert loudly — which is
// what you WANT on a payments contract (silent success on garbage
// calldata is how "accidental transfer + wrong function" funds get
// stuck). Here we make the dispatch explicit.
//
// TODO: Implement `fallback` so ANY unknown call with value or data
// reverts with UnknownCall(bytes). Plain ETH transfers must keep
// working through receive.

import "forge-std/Test.sol";

contract Dispatcher {
    error UnknownCall(bytes data);

    uint256 public receivedCount;

    // TODO: catch every call that doesn't match a real function and
    // revert UnknownCall with the raw calldata

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
        // And the revert data must be OUR error, not a generic one:
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
