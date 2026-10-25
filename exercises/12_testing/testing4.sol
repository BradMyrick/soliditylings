// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// testing4 — signing in tests
// When a contract gates an action behind a signature, your test needs
// to BE the signer. `vm.addr(pk)` derives the address,
// `vm.sign(pk, digest)` produces (v, r, s). Together they turn any
// test into the off-chain signer — no wallet, no network.
//
// TODO: Complete `testReleaseWithValidSig` — sign the digest the way
// `release` computes it, and pass the signature through.

import "forge-std/Test.sol";

contract SigGate {
    address public immutable signer;

    constructor(address s) {
        signer = s;
    }

    function digestFor(address to, uint256 amount) public pure returns (bytes32) {
        bytes32 inner = keccak256(abi.encode("release", to, amount));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", inner));
    }

    function release(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 digest = digestFor(to, amount);
        require(ecrecover(digest, v, r, s) == signer, "bad sig");
        payable(to).transfer(amount);
    }

    receive() external payable {}
}

contract Testing4Test is Test {
    SigGate gate;
    uint256 constant SIGNER_PK = 0x51C6;

    function setUp() public {
        gate = new SigGate(vm.addr(SIGNER_PK));
        vm.deal(address(gate), 10 ether);
    }

    function testReleaseWithValidSig() public {
        address to = address(0xBEEF);
        uint256 amount = 1 ether;

        // TODO: compute the digest, sign it with SIGNER_PK, call release

        fail("unreachable if the signed release succeeded");
    }

    function testBadSigRejected() public {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xBA0BAD, gate.digestFor(address(0xBEEF), 1 ether));
        vm.expectRevert();
        gate.release(address(0xBEEF), 1 ether, v, r, s);
    }
}
