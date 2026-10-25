// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Domain {
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    string public constant NAME = "SaifuroEscrow";
    string public constant VERSION = "1";

    function domainSeparator(uint256 chainId, address verifyingContract)
        external
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                chainId,
                verifyingContract
            )
        );
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
