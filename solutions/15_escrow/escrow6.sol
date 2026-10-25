// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract ArbiterEscrow {
    enum Outcome {
        None,
        PaySeller,
        RefundBuyer
    }

    enum State {
        Funded,
        Resolved
    }

    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    State public state;

    mapping(address => uint256) public withdrawable;

    error OnlyArbiter();
    error WrongState();
    error NothingToWithdraw();

    constructor(address _buyer, address _seller) payable {
        require(msg.value > 0, "empty");
        require(_buyer != _seller, "same party");
        buyer = _buyer;
        seller = _seller;
        arbiter = msg.sender;
        amount = msg.value;
        state = State.Funded;
    }

    // Pull-payment resolution: accounting only, no interactions.
    function resolve(Outcome outcome) external {
        require(msg.sender == arbiter, OnlyArbiter());
        require(state == State.Funded, WrongState());
        require(outcome != Outcome.None, "no outcome");

        state = State.Resolved;
        if (outcome == Outcome.PaySeller) {
            withdrawable[seller] += amount;
        } else {
            withdrawable[buyer] += amount;
        }
    }

    function withdraw() external {
        uint256 amt = withdrawable[msg.sender];
        if (amt == 0) revert NothingToWithdraw();
        withdrawable[msg.sender] = 0; // effect
        payable(msg.sender).transfer(amt); // interaction
    }

    receive() external payable {}
}

contract Escrow6Test is Test {
    address buyer = makeAddr("buyer");
    address seller = makeAddr("seller");

    function deploy() internal returns (ArbiterEscrow e) {
        vm.deal(address(this), 10 ether);
        // The TEST contract deploys (and thus arbitrates); the buyer is
        // merely the counterparty who can be made whole.
        e = new ArbiterEscrow{value: 1 ether}(buyer, seller);
    }

    function testResolvePaysSellerViaPull() public {
        ArbiterEscrow e = deploy();

        e.resolve(ArbiterEscrow.Outcome.PaySeller);

        vm.prank(seller);
        e.withdraw();

        assertEq(seller.balance, 1 ether);
        assertTrue(e.state() == ArbiterEscrow.State.Resolved);
    }

    function testResolveRefundsBuyerViaPull() public {
        ArbiterEscrow e = deploy();

        e.resolve(ArbiterEscrow.Outcome.RefundBuyer);

        vm.prank(buyer);
        e.withdraw();

        assertEq(buyer.balance, 1 ether, "buyer made whole");
        assertEq(seller.balance, 0);
    }

    function testOnlyArbiterResolves() public {
        ArbiterEscrow e = deploy();

        vm.prank(seller);
        vm.expectRevert(ArbiterEscrow.OnlyArbiter.selector);
        e.resolve(ArbiterEscrow.Outcome.PaySeller);
    }

    function testCannotResolveTwice() public {
        ArbiterEscrow e = deploy();
        e.resolve(ArbiterEscrow.Outcome.PaySeller);

        vm.expectRevert(ArbiterEscrow.WrongState.selector);
        e.resolve(ArbiterEscrow.Outcome.RefundBuyer);
    }
}
