// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// signatures4 — EIP-712 part 1: the domain separator
// Typed structured data signing (EIP-712) makes signatures READABLE in
// wallets and — critically — BOUND to a context. The domain separator
// scopes every signature to (name, version, chainId, verifyingContract):
// a signature for Escrow v1 on Base can't be replayed against Escrow v2
// or the same contract on Ethereum mainnet.
//
//   DOMAIN_TYPEHASH = keccak256(
//     "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
//   );
//   domainSeparator = keccak256(abi.encode(
//     DOMAIN_TYPEHASH,
//     keccak256(bytes(name)),
//     keccak256(bytes(version)),
//     chainId,
//     verifyingContract
//   ));
//
// TODO: Implement `domainSeparator` following the recipe above.

import "forge-std/Test.sol";

contract Domain {
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    string public constant NAME = "SaifuroEscrow";
    string public constant VERSION = "1";

    // TODO: keccak of the fully-encoded domain
    function domainSeparator(uint256 chainId, address verifyingContract)
        external
        pure
        returns (bytes32)
    {
        return bytes32(0); // REPLACE ME
    }
}

contract Signatures4Test is Test {
    Domain target;

    function setUp() public {
        target = new Domain();
    }

    function testDomainSeparator() public {
        uint256 chainId = 8453; // Base
        address self = address(this);
        bytes32 expected = keccak256(
            abi.encode(
                target.DOMAIN_TYPEHASH(),
                keccak256(bytes("SaifuroEscrow")),
                keccak256(bytes("1")),
                chainId,
                self
            )
        );
        assertEq(target.domainSeparator(chainId, self), expected);
    }
}
