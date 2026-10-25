// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract StrictVerify {
    error Malleable();

    uint256 constant SECP256K1_N =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function verify(bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        external
        pure
        returns (address)
    {
        if (uint256(s) > SECP256K1_N / 2) revert Malleable(); // EIP-2 bounds
        return ecrecover(digest, v, r, s);
    }
}

contract Signatures7Test is Test {
    StrictVerify target;
    uint256 constant PK = 0xA11CE;

    uint256 constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function setUp() public {
        target = new StrictVerify();
    }

    function testNormalSignaturePasses() public {
        bytes32 digest = keccak256("strict");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK, digest);
        uint256 sUint = uint256(s);
        if (sUint > N / 2) {
            s = bytes32(N - sUint);
            v = v == 27 ? 28 : 27;
        }
        assertEq(target.verify(digest, v, r, s), vm.addr(PK));
    }

    function testFlippedSignatureRejected() public {
        bytes32 digest = keccak256("strict");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK, digest);

        if (uint256(s) > N / 2) {
            s = bytes32(N - uint256(s));
            v = v == 27 ? 28 : 27;
        }

        bytes32 sFlipped = bytes32(N - uint256(s));
        uint8 vFlipped = v == 27 ? 28 : 27;

        assertEq(ecrecover(digest, vFlipped, r, sFlipped), vm.addr(PK));

        vm.expectRevert(StrictVerify.Malleable.selector);
        target.verify(digest, vFlipped, r, sFlipped);
    }
}
