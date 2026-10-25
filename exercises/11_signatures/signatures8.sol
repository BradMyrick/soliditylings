// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// signatures8 — expiry
// A signature that never expires is a liability that never expires.
// Standard practice (EIP-2612 permit did it first): the deadline is
// PART OF the signed payload, and the contract enforces it against
// block.timestamp. Signers bound their authorization in time; the
// chain enforces the bound.
//
// Block timestamp notes for the interview: it's set by the block
// proposer, monotonic within a chain, and can drift ~a few seconds —
// fine for deadlines, never fine for randomness.
//
// TODO: `execute` must revert with `Expired()` when the deadline has
// passed. The deadline is already inside the digest, so the signer
// chose it — you just have to enforce it.

import "forge-std/Test.sol";

contract TimedOrder {
    error Expired();
    error BadSigner();

    address public immutable authority;

    constructor(address a) {
        authority = a;
    }

    function execute(uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 digest = keccak256(abi.encode("order", deadline));

        // TODO: enforce the deadline before anything moves

        if (ecrecover(digest, v, r, s) != authority) revert BadSigner();
    }
}

contract Signatures8Test is Test {
    TimedOrder order;
    uint256 constant PK = 0xA11CE;

    function setUp() public {
        order = new TimedOrder(vm.addr(PK));
    }

    function executeSig(uint256 deadline) internal {
        bytes32 digest = keccak256(abi.encode("order", deadline));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK, digest);
        order.execute(deadline, v, r, s);
    }

    function testFreshSignatureExecutes() public {
        executeSig(block.timestamp + 1 hours); // no revert
    }

    function testExpiredSignatureReverts() public {
        vm.warp(1_000_000);
        uint256 deadline = 500_000; // long past
        vm.expectRevert(TimedOrder.Expired.selector);
        executeSig(deadline);
    }
}
