// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Vault {
    event Deposit(address indexed depositor, uint256 amount);

    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {}
}

contract Testing2Test is Test {
    Vault vault;

    event Deposit(address indexed depositor, uint256 amount);

    function setUp() public {
        vault = new Vault();
    }

    function testStateUpdated() public {
        vault.deposit{value: 1 ether}();
        assertEq(vault.balances(address(this)), 1 ether);
    }

    function testDepositEmits() public {
        vm.expectEmit(true, true, false, true);
        emit Deposit(address(this), 1 ether); // what we expect
        vault.deposit{value: 1 ether}(); // when we expect it
    }

    receive() external payable {}
}
