// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Faucet {
    mapping(address => uint256) public owed;

    function credit(address to, uint256 amount) external {
        owed[to] += amount;
    }

    function withdraw() external {
        uint256 amount = owed[msg.sender];
        owed[msg.sender] = 0;
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "Transfer failed"); // FIXED: loud failure
    }

    receive() external payable {}
}

contract Rejector {
    function burn() external pure returns (uint256) {
        uint256 x;
        for (uint256 i = 0; i < 1000; i++) {
            x += i;
        }
        return x;
    }
}

contract UncheckedCallTest is Test {
    Faucet faucet;
    Rejector rejector;

    function setUp() public {
        faucet = new Faucet();
        vm.deal(address(faucet), 10 ether);
        rejector = new Rejector();
    }

    function testWithdrawToRejectorReverts() public {
        faucet.credit(address(rejector), 1 ether);
        vm.prank(address(rejector));
        vm.expectRevert();
        faucet.withdraw();
    }

    function testWithdrawToReceiverWorks() public {
        faucet.credit(address(this), 1 ether);
        faucet.withdraw();
        assertEq(faucet.owed(address(this)), 0, "debt cleared");
    }

    receive() external payable {}
}
