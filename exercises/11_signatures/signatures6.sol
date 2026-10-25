// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// signatures6 — replay protection
// A valid signature is valid FOREVER. If your contract accepts the
// same (digest, v, r, s) twice, the second use is a replay — money
// leaves twice on one signature. Every signature scheme needs a
// spend flag: a nonce consumed atomically with the action.
//
// TODO: Track consumed signatures in `used` (the digest is a natural
// key). `claim` must (1) reject a used digest with `AlreadyUsed()` and
// (2) mark it used before paying — checks-effects-interactions
// applies to signatures too.

import "forge-std/Test.sol";

contract NonceClaims {
    error AlreadyUsed();
    error BadSigner();

    address public immutable authority;
    mapping(bytes32 => bool) public used;

    constructor(address a) {
        authority = a;
    }

    function claim(bytes32 digest, uint8 v, bytes32 r, bytes32 s) external {
        // TODO: reject replayed digests

        if (ecrecover(digest, v, r, s) != authority) revert BadSigner();

        // TODO: consume the digest BEFORE the interaction

        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}

contract Signatures6Test is Test {
    NonceClaims claims;
    uint256 constant PK = 0xA11CE;
    address authority;

    function setUp() public {
        authority = vm.addr(PK);
        claims = new NonceClaims(authority);
        vm.deal(address(claims), 2 ether);
        vm.deal(address(this), 0);
    }

    function signDigest() internal returns (bytes32, uint8, bytes32, bytes32) {
        bytes32 digest = keccak256(abi.encode("pay", address(this)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK, digest);
        return (digest, v, r, s);
    }

    function testFirstClaimPays() public {
        (bytes32 d, uint8 v, bytes32 r, bytes32 s) = signDigest();
        claims.claim(d, v, r, s);
        assertEq(address(this).balance, 2 ether);
        assertTrue(claims.used(d), "digest must be consumed");
    }

    function testReplayRejected() public {
        (bytes32 d, uint8 v, bytes32 r, bytes32 s) = signDigest();
        claims.claim(d, v, r, s);

        vm.expectRevert(NonceClaims.AlreadyUsed.selector);
        claims.claim(d, v, r, s); // same sig, second time
    }
}
