// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// security_deadline — AUDIT FINDING: "missing deadline on signed action"
// The mempool is adversarial: a signed or submitted action sits in
// public view where bots and backlogged blocks can delay it. Without a
// deadline, "buy at this price" or "release at this verdict" can
// execute at whatever world state eventually includes it. This is the
// front-running family — the defense is making the transaction
// EXPIRE.
//
// TODO: `claimWithPermit` must revert with `Expired()` when
// `block.timestamp > deadline`. Verdict: expired transactions are
// dead transactions.

import "forge-std/Test.sol";

contract ClaimPool {
    error Expired();

    mapping(address => uint256) public claims;

    function setClaim(address who, uint256 amount) external {
        claims[who] = amount;
    }

    function claimWithPermit(uint256 amount, uint256 deadline) external {
        // TODO: reject when the deadline has passed
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
}
