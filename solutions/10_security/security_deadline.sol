// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract ClaimPool {
    error Expired();

    mapping(address => uint256) public claims;

    function setClaim(address who, uint256 amount) external {
        claims[who] = amount;
    }

    function claimWithPermit(uint256 amount, uint256 deadline) external {
        if (block.timestamp > deadline) revert Expired(); // FIXED
        claims[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}

contract DeadlineTest is Test {
    ClaimPool pool;

    function setUp() public {
        pool = new ClaimPool();
        vm.deal(address(pool), 10 ether);
        vm.deal(address(this), 0); // deterministic assert below
        pool.setClaim(address(this), 5 ether);
    }

    function testClaimBeforeDeadline() public {
        pool.claimWithPermit(1 ether, block.timestamp + 1 hours);
        assertEq(address(this).balance, 1 ether);
    }

    function testClaimAfterDeadlineReverts() public {
        vm.warp(block.timestamp + 2 hours);
        vm.expectRevert(ClaimPool.Expired.selector);
        pool.claimWithPermit(1 ether, block.timestamp - 1);
    }

    receive() external payable {}
}
