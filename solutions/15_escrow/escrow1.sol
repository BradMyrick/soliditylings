// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract SimpleEscrow {
    enum State {
        Empty,
        Funded,
        Released,
        Refunded
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
        if (state != State.Funded) revert WrongState(); // guard
        state = State.Released; // effect first
        payable(seller).transfer(amount); // interaction last
    }

    function refund() external {
        if (state != State.Funded) revert WrongState();
        state = State.Refunded;
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
        e.release();

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
