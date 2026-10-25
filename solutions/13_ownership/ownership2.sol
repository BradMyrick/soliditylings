// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract TwoStepOwnable {
    address public owner;
    address public pendingOwner;

    event OwnershipProposed(address indexed candidate);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function proposeOwnership(address candidate) external onlyOwner {
        pendingOwner = candidate;
        emit OwnershipProposed(candidate);
    }

    function claimOwnership() external {
        require(msg.sender == pendingOwner, "not pending owner");
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }
}

contract Ownership2Test is Test {
    TwoStepOwnable ownable;
    address successor = makeAddr("successor");

    function setUp() public {
        ownable = new TwoStepOwnable();
    }

    function testClaimInstallsOwner() public {
        ownable.proposeOwnership(successor);

        vm.prank(successor);
        ownable.claimOwnership();

        assertEq(ownable.owner(), successor, "successor must be installed");
        assertEq(ownable.pendingOwner(), address(0), "proposal must be cleared");
    }

    function testStrangerCannotClaim() public {
        ownable.proposeOwnership(successor);

        vm.prank(address(0xBA0BAD));
        vm.expectRevert();
        ownable.claimOwnership();

        assertEq(ownable.owner(), address(this), "owner unchanged");
    }

    function testWrongAddressProposalIsRecoverable() public {
        ownable.proposeOwnership(address(0xDEAD));
        ownable.proposeOwnership(successor);

        vm.prank(successor);
        ownable.claimOwnership();
        assertEq(ownable.owner(), successor);
    }
}
