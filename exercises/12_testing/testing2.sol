// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// testing2 — event assertions
// Events are your observability layer — indexers, runbooks, and audit
// evidence all read them. A test that checks state but not events can
// pass while the receipt tells operators nothing.
//
//   vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData);
//   emit Deposit(expectedEmitter, expectedAmount); // what we expect
//   vault.deposit{value: 1 ether}();               // when we expect it
//
// TODO: Complete `testDepositEmits` — expect the Deposit event with
// the depositor and amount, then make the deposit that fires it.

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

    event Deposit(address indexed depositor, uint256 amount); // mirror

    function setUp() public {
        vault = new Vault();
    }

    function testStateUpdated() public {
        vault.deposit{value: 1 ether}();
        assertEq(vault.balances(address(this)), 1 ether);
    }

    function testDepositEmits() public {
        // TODO: expect the Deposit event with (address(this), 1 ether)
        // TODO: then trigger it with a 1 ether deposit

        fail("unreachable if you wired the emit check above");
    }
}
