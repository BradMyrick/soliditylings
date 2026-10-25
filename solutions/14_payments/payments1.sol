// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Payer {
    mapping(address => uint256) public owed;

    function credit(address to, uint256 amount) external {
        owed[to] += amount;
    }

    function withdrawWithTransfer() external {
        uint256 amount = owed[msg.sender];
        owed[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function withdrawWithCall() external {
        uint256 amount = owed[msg.sender]; // checks
        owed[msg.sender] = 0; // effects
        (bool ok,) = msg.sender.call{value: amount}(""); // interaction
        require(ok, "Transfer failed"); // and CHECK the interaction
    }

    receive() external payable {}
}

contract FancyWallet {
    uint256 public lastPayment;

    receive() external payable {
        lastPayment = msg.value;
    }
}

contract Payments1Test is Test {
    Payer payer;
    FancyWallet wallet;

    function setUp() public {
        payer = new Payer();
        wallet = new FancyWallet();
        vm.deal(address(payer), 10 ether);
    }

    function testTransferBricksOnFancyWallet() public {
        payer.credit(address(wallet), 1 ether);
        vm.prank(address(wallet));
        vm.expectRevert();
        payer.withdrawWithTransfer();
    }

    function testCallSucceedsOnFancyWallet() public {
        payer.credit(address(wallet), 1 ether);

        vm.prank(address(wallet));
        payer.withdrawWithCall();

        assertEq(address(wallet).balance, 1 ether);
        assertEq(wallet.lastPayment(), 1 ether, "wallet ran its own logic");
        assertEq(payer.owed(address(wallet)), 0, "debt cleared");
    }
}
