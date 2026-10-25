// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// escrow1 — the state machine
// Every escrow is a state machine with GUARDED transitions:
//
//   Empty → Funded → Released
//               └──→ Refunded
//
// The guards ARE the security: an action is legal in exactly one
// state. A missing guard is how "release twice" and "refund after
// release" happen — auditors read state machines first.
//
// TODO: Complete `release`: only legal from Funded, pays the seller,
// lands in Released. `refund` is written — read it, then mirror it.

import "forge-std/Test.sol";

contract SimpleEscrow {
    enum State {
        Empty, // 0 — nothing here
        Funded, // 1 — buyer's ETH is locked
        Released, // 2 — seller paid
        Refunded // 3 — buyer made whole
    }

    address public buyer;
    address public seller;
    uint256 public amount;
    State public state;

    error WrongState();

    constructor(address _seller) payable {
        require(msg.value > 0, "empty escrow");
        buyer = msg.sender;
        seller = _seller;
        amount = msg.value;
        state = State.Funded;
    }

    function release() external {
        // TODO: require the state is Funded (revert WrongState)

        // TODO: transition BEFORE the interaction (CEI)

        payable(seller).transfer(amount);
    }

    function refund() external {
        if (state != State.Funded) revert WrongState();
        state = State.Refunded; // effect first
        payable(buyer).transfer(amount);
    }
}

contract Escrow1Test is Test {
    address buyer = makeAddr("buyer");
    address seller = makeAddr("seller");

    function deploy() internal returns (SimpleEscrow e) {
        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        e = new SimpleEscrow{value: 1 ether}(seller);
    }

    function testReleasePaysSeller() public {
        SimpleEscrow e = deploy();
        e.release();
        assertEq(seller.balance, 1 ether);
        assertTrue(e.state() == SimpleEscrow.State.Released);
    }

    function testDoubleReleaseReverts() public {
        SimpleEscrow e = deploy();
        e.release(); // state: Released

        vm.expectRevert(SimpleEscrow.WrongState.selector);
        e.release();
    }

    function testRefundAfterReleaseReverts() public {
        SimpleEscrow e = deploy();
        e.release();

        vm.expectRevert(SimpleEscrow.WrongState.selector);
        e.refund();
    }
}
