// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// variables2
// `address` is a 20-byte type unique to Ethereum — it holds an account
// or contract address, and it's the type you'll use more than any other
// when modeling who owns what.
//
// TODO: The constructor assigns to `owner` but the variable is never
// declared. Declare it as a PUBLIC state variable of type `address`.

import "forge-std/Test.sol";

contract Variables2 {
    // TODO: declare `owner` here

    constructor() {
        // The deployer of the contract is available as `msg.sender`.
        owner = msg.sender;
    }
}

contract Variables2Test is Test {
    function testOwnerIsDeployer() public {
        Variables2 vars = new Variables2();
        // In a Foundry test, the deploying contract is the test itself.
        assertEq(vars.owner(), address(this), "owner should be the deployer");
    }
}
