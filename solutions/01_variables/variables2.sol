// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Variables2 {
    address public owner;

    constructor() {
        owner = msg.sender;
    }
}

contract Variables2Test is Test {
    function testOwnerIsDeployer() public {
        Variables2 vars = new Variables2();
        assertEq(vars.owner(), address(this), "owner should be the deployer");
    }
}
