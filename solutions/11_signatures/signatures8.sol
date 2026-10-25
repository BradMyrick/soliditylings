// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract TimedOrder {
    error Expired();
    error BadSigner();

    address public immutable authority;

    constructor(address a) {
        authority = a;
    }

    function execute(uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        if (block.timestamp > deadline) revert Expired(); // FIXED: enforce the signer's deadline

        bytes32 digest = keccak256(abi.encode("order", deadline));

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
        executeSig(block.timestamp + 1 hours);
    }

    function testExpiredSignatureReverts() public {
        vm.warp(1_000_000);
        uint256 deadline = 500_000;
        vm.expectRevert(TimedOrder.Expired.selector);
        executeSig(deadline);
    }
}
