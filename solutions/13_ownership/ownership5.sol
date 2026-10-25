// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Renouncable {
    address public owner;

    event Renounced();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
        emit Renounced();
    }

    function setFee(uint256 f) external onlyOwner {
        fee = f;
    }

    uint256 public fee;
}

contract Ownership5Test is Test {
    Renouncable target;

    function setUp() public {
        target = new Renouncable();
    }

    function testRenounceKillsAdminPlane() public {
        target.setFee(5);
        assertEq(target.fee(), 5);

        target.renounceOwnership();
        assertEq(target.owner(), address(0), "owner must be zeroed");

        vm.expectRevert();
        target.setFee(10);
        assertEq(target.fee(), 5, "fee is frozen forever");
    }

    function testOnlyOwnerCanRenounce() public {
        vm.prank(address(0xBA0BAD));
        vm.expectRevert();
        target.renounceOwnership();
        assertEq(target.owner(), address(this));
    }
}
