// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Mappings1 {
    mapping(address => uint256) public balances;

    function setBalance(address user, uint256 amount) public {
        balances[user] = amount;
    }
}

contract Mappings1Test is Test {
    Mappings1 target;

    function setUp() public {
        target = new Mappings1();
    }

    function testSetBalance() public {
        address alice = address(0xA11CE);
        target.setBalance(alice, 100);
        assertEq(target.balances(alice), 100);

        address bob = address(0xB0B);
        assertEq(target.balances(bob), 0, "unset keys are 0, not an error");
    }
}
