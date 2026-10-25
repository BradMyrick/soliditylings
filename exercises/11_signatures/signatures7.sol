// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// signatures7 — signature malleability
// secp256k1 has a symmetry: for any signature (v, r, s), the tuple
// (v', r, n-s) verifies against the SAME digest. Both are "valid",
// but they have different bytes — a dedup keyed on raw signature
// bytes sees two different signatures while your accounting sees one
// authorization. That's a replay with extra steps.
//
// The EIP-2 fix is a bounds check on s: it must be in the LOWER half
// of the curve order. (ECDSA libraries do this for you; here you are
// the library.)
//
// TODO: In `verify`, reject signatures where s > secp256k1n / 2 with
// `Malleable()`. The test forges the flipped variant — only the
// bounds check stops it.

import "forge-std/Test.sol";

contract StrictVerify {
    error Malleable();

    // secp256k1 curve order n
    uint256 constant SECP256K1_N =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function verify(bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        external
        pure
        returns (address)
    {
        // TODO: reject high-s signatures

        return ecrecover(digest, v, r, s);
    }
}

contract Signatures7Test is Test {
    StrictVerify target;
    uint256 constant PK = 0xA11CE;

    // Mirror the curve constant to forge the flipped signature.
    uint256 constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function setUp() public {
        target = new StrictVerify();
    }

    function testNormalSignaturePasses() public {
        bytes32 digest = keccak256("strict");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK, digest);
        uint256 sUint = uint256(s);
        if (sUint > N / 2) {
            // Normalize our own signature first so we start low-s.
            s = bytes32(N - sUint);
            v = v == 27 ? 28 : 27;
        }
        assertEq(target.verify(digest, v, r, s), vm.addr(PK));
    }

    function testFlippedSignatureRejected() public {
        bytes32 digest = keccak256("strict");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK, digest);

        // Normalize to low-s first, so the flip below is GUARANTEED
        // to produce the high-s variant.
        if (uint256(s) > N / 2) {
            s = bytes32(N - uint256(s));
            v = v == 27 ? 28 : 27;
        }

        // Flip to the high-s variant — still a "valid" ECDSA signature.
        bytes32 sFlipped = bytes32(N - uint256(s));
        uint8 vFlipped = v == 27 ? 28 : 27;

        // Sanity: the flipped sig genuinely recovers the signer.
        assertEq(ecrecover(digest, vFlipped, r, sFlipped), vm.addr(PK));

        // But it must not pass the strict verifier.
        vm.expectRevert(StrictVerify.Malleable.selector);
        target.verify(digest, vFlipped, r, sFlipped);
    }
}
