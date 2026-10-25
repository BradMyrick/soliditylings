// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract TimeoutEscrow {
    enum State {
        Empty,
        Funded,
        Released,
        Refunded
    }

    struct Escrow {
        address buyer;
        address seller;
        uint256 amount;
        uint256 expiresAt;
        State state;
    }

    mapping(bytes32 => Escrow) public escrows;

    error NotExpired();
    error WrongState();

    function fund(bytes32 id, address buyer, address seller, uint256 lifetime) external payable {
        escrows[id] = Escrow(buyer, seller, msg.value, block.timestamp + lifetime, State.Funded);
    }

    function release(bytes32 id) external {
        Escrow storage e = escrows[id];
        if (e.state != State.Funded) revert WrongState();
        if (block.timestamp >= e.expiresAt) revert NotExpired();
        e.state = State.Released;
        payable(e.seller).transfer(e.amount);
    }

    // FIXED: self-serve — after the clock runs out, ANYONE can trigger
    // the buyer's exit. No permission checks beyond state + clock.
    function refund(bytes32 id) external {
        Escrow storage e = escrows[id];
        if (e.state != State.Funded) revert WrongState();
        if (block.timestamp < e.expiresAt) revert NotExpired();
        e.state = State.Refunded;
        payable(e.buyer).transfer(e.amount);
    }

    receive() external payable {}
}

contract Escrow4Test is Test {
    address seller = makeAddr("seller");
    TimeoutEscrow escrow;
    address buyer = makeAddr("buyer");

    function setUp() public {
        escrow = new TimeoutEscrow();
        vm.deal(buyer, 1 ether);
    }

    function fundDefault() internal returns (bytes32) {
        bytes32 id = bytes32("T1");
        vm.prank(buyer);
        escrow.fund{value: 1 ether}(id, buyer, seller, 7 days);
        return id;
    }

    function testRefundBeforeExpiryReverts() public {
        bytes32 id = fundDefault();
        vm.warp(block.timestamp + 6 days);

        vm.expectRevert(TimeoutEscrow.NotExpired.selector);
        escrow.refund(id);
    }

    function testRefundAfterExpiryIsSelfServe() public {
        bytes32 id = fundDefault();
        vm.warp(block.timestamp + 8 days);

        address stranger = makeAddr("stranger");
        vm.prank(stranger);
        escrow.refund(id);

        assertEq(buyer.balance, 1 ether, "buyer is made whole");
        (, , , , TimeoutEscrow.State s) = escrow.escrows(id);
        assertTrue(s == TimeoutEscrow.State.Refunded);
    }

    function testVerdictLosesToClock() public {
        bytes32 id = fundDefault();
        vm.warp(block.timestamp + 8 days);

        vm.expectRevert(TimeoutEscrow.NotExpired.selector);
        escrow.release(id);
    }
}
