// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract RaceEscrow {
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
        State state;
    }

    mapping(bytes32 => Escrow) public escrows;

    error WrongState();

    function fund(bytes32 id, address buyer, address seller) external payable {
        escrows[id] = Escrow(buyer, seller, msg.value, State.Funded);
    }

    function release(bytes32 id) external {
        Escrow storage e = escrows[id];
        if (e.state != State.Funded) revert WrongState();
        e.state = State.Released;
        payable(e.seller).transfer(e.amount);
    }

    // FIXED: the missing state guard — the state transition IS the lock
    function refund(bytes32 id) external {
        Escrow storage e = escrows[id];
        if (e.state != State.Funded) revert WrongState();

        e.state = State.Refunded;
        payable(e.buyer).transfer(e.amount);
    }

    receive() external payable {}
}

contract Escrow5Test is Test {
    RaceEscrow escrow;
    address buyer = makeAddr("buyer");
    address seller = makeAddr("seller");

    function setUp() public {
        escrow = new RaceEscrow();
        vm.deal(address(this), 10 ether);
    }

    function fundDefault() internal returns (bytes32) {
        bytes32 id = bytes32("R1");
        escrow.fund{value: 1 ether}(id, buyer, seller);
        return id;
    }

    function testReleaseThenRefundReverts() public {
        bytes32 id = fundDefault();
        escrow.release(id);

        vm.expectRevert(RaceEscrow.WrongState.selector);
        escrow.refund(id);

        assertEq(seller.balance, 1 ether);
        assertEq(buyer.balance, 0);
    }

    function testRefundThenReleaseReverts() public {
        bytes32 id = fundDefault();
        escrow.refund(id);

        vm.expectRevert(RaceEscrow.WrongState.selector);
        escrow.release(id);

        assertEq(buyer.balance, 1 ether);
        assertEq(seller.balance, 0);
    }

    function testExactlyOnePayoutPerEscrow() public {
        bytes32 id = fundDefault();
        escrow.release(id);
        assertEq(address(escrow).balance, 0, "pot is empty after one payout");
    }
}
