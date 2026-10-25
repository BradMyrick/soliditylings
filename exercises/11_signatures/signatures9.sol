// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// signatures9 — THE VERIFIER (capstone of the signature arc)
// This is the real shape of the escrow interview component: "The
// contracts check our signature, the audience, and the expiry before
// anything moves." Piece by piece:
//
//   signature — EIP-191 personal-sign digest, recovered with ecrecover,
//               must equal the trusted verifier address
//   audience  — the digest binds (escrowId, recipient): a verdict for
//               one escrow can never release another, and a verdict for
//               Alice can never pay Bob
//   expiry    — the deadline is inside the signed payload and enforced
//               against block.timestamp
//   replay    — each escrow's verdict is consumable exactly once
//
// Everything runs through `verify` — no storage moves, no ETH moves,
// until every check passes. You own this path onchain.
//
// TODO: Complete `verify` with the three checks and the digest
// composed exactly as in `digestFor`.

import "forge-std/Test.sol";

contract Verifier {
    error NotVerifier();
    error Expired();
    error AlreadyConsumed();

    address public immutable verifier; // the trusted signing key
    mapping(uint256 => bool) public consumed; // replay guard per escrow

    constructor(address v) {
        verifier = v;
    }

    /// The exact digest the verifier signs (EIP-191 personal-sign over
    /// a typed payload: escrow id, recipient, amount, deadline).
    function digestFor(uint256 escrowId, address recipient, uint256 amount, uint256 deadline)
        public
        pure
        returns (bytes32)
    {
        bytes32 inner = keccak256(abi.encode("release", escrowId, recipient, amount, deadline));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", inner));
    }

    /// Split a 65-byte personal-sign signature into (v, r, s).
    function split(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "bad length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function verify(uint256 escrowId, address recipient, uint256 amount, uint256 deadline, bytes memory sig)
        external
        returns (bool)
    {
        (uint8 v, bytes32 r, bytes32 s) = split(sig);

        // TODO 1: reject consumed escrows (revert AlreadyConsumed)

        // TODO 2: reject expired deadlines (revert Expired)

        // TODO 3: recover the signer over the digest; revert
        //         NotVerifier if it is not the trusted verifier

        // TODO 4: consume — mark this escrow's verdict spent

        return true;
    }
}

contract Signatures9Test is Test {
    Verifier verifier;
    uint256 constant VERIFIER_PK = 0xCE0; // "ceo" — the off-chain signer
    address verifierAddr;

    function setUp() public {
        verifierAddr = vm.addr(VERIFIER_PK);
        verifier = new Verifier(verifierAddr);
    }

    function sign(uint256 escrowId, address recipient, uint256 amount, uint256 deadline)
        internal
        view
        returns (bytes memory)
    {
        bytes32 digest = verifier.digestFor(escrowId, recipient, amount, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(VERIFIER_PK, digest);
        return abi.encodePacked(r, s, v);
    }

    function testHappyPath() public {
        bytes memory sig = sign(1, address(this), 1 ether, block.timestamp + 1 hours);
        assertTrue(verifier.verify(1, address(this), 1 ether, block.timestamp + 1 hours, sig));
    }

    function testWrongSignerRejected() public {
        // A stranger's key signs the same payload.
        bytes32 digest = verifier.digestFor(1, address(this), 1 ether, block.timestamp + 1 hours);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xDEAD, digest);

        vm.expectRevert(Verifier.NotVerifier.selector);
        verifier.verify(1, address(this), 1 ether, block.timestamp + 1 hours, abi.encodePacked(r, s, v));
    }

    function testExpiredRejected() public {
        uint256 deadline = block.timestamp - 1;
        bytes memory sig = sign(1, address(this), 1 ether, deadline);

        vm.expectRevert(Verifier.Expired.selector);
        verifier.verify(1, address(this), 1 ether, deadline, sig);
    }

    function testReplayRejected() public {
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = sign(1, address(this), 1 ether, deadline);

        assertTrue(verifier.verify(1, address(this), 1 ether, deadline, sig));
        vm.expectRevert(Verifier.AlreadyConsumed.selector);
        verifier.verify(1, address(this), 1 ether, deadline, sig);
    }

    function testAudienceIsBound() public {
        // Signature names recipient X — presenting it for recipient Y
        // changes the digest, so it can't pass the verifier check.
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = sign(1, address(0xA), 1 ether, deadline);

        vm.expectRevert(Verifier.NotVerifier.selector); // digest no longer matches the sig
        verifier.verify(1, address(0xB), 1 ether, deadline, sig);
    }
}
