// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// mappings1
// A mapping is Solidity's hash table: `mapping(KeyType => ValueType)`.
// Every possible key exists — unset keys simply return the value type's
// zero value. Keys are NOT enumerable; all you can do is read and write
// by key. A `public` mapping gets a free getter taking the key.
//
// TODO: 1. Declare a public mapping from address => uint256 named `balances`.
//       2. In `setBalance`, write `amount` at key `user`.

import "forge-std/Test.sol";

contract Mappings1 {
    // TODO: declare `balances` here

    function setBalance(address user, uint256 amount) public {
        // TODO: set the balance for `user`
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

        // Unset keys read as the zero value.
        address bob = address(0xB0B);
        assertEq(target.balances(bob), 0, "unset keys are 0, not an error");
    }
}
