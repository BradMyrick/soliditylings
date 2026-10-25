// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Vault {
    error Insufficient(uint256 requested, uint256 available);
    error ZeroAmount();

    mapping(address => uint256) public balances;

    function deposit() external payable {
        require(msg.value > 0, "empty deposit");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        uint256 avail = balances[msg.sender];
        if (amount > avail) revert Insufficient(amount, avail);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}

contract Testing1Test is Test {
    Vault vault;

    function setUp() public {
        vault = new Vault();
    }

    function testWithdrawMoreThanBalance() public {
        vault.deposit{value: 1 ether}();

        vm.expectRevert(abi.encodeWithSelector(Vault.Insufficient.selector, 2 ether, 1 ether));
        vault.withdraw(2 ether);
    }

    function testWithdrawZero() public {
        vm.expectRevert(Vault.ZeroAmount.selector);
        vault.withdraw(0);
    }

    receive() external payable {}
}
