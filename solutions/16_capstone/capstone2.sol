// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";

contract PauseGuardian {
    address public operator;
    bool public paused;

    error NotOperator();

    event Paused(bool paused);

    constructor() {
        operator = msg.sender;
    }

    function setPaused(bool p) external {
        require(msg.sender == operator, NotOperator());
        paused = p;
        emit Paused(p);
    }
}

contract DeployGuardian is Script {
    PauseGuardian public guardian;

    function run() external {
        vm.startBroadcast();
        guardian = new PauseGuardian();
        vm.stopBroadcast();
    }
}

contract Capstone2Test is Test {
    function deploy() internal returns (PauseGuardian g) {
        DeployGuardian script = new DeployGuardian();
        script.run();
        g = script.guardian();
        assertTrue(address(g) != address(0), "script must deploy the guardian");
        assertFalse(g.paused(), "starts unpaused");
    }

    function testScriptDeploysHealthyGuardian() public {
        deploy();
    }

    function testPauseSwitchWorks() public {
        PauseGuardian g = deploy();

        vm.prank(g.operator());
        g.setPaused(true);
        assertTrue(g.paused());

        vm.prank(g.operator());
        g.setPaused(false);
        assertFalse(g.paused());
    }

    function testStrangerCannotPause() public {
        PauseGuardian g = deploy();

        vm.prank(address(0xBA0BAD));
        vm.expectRevert(PauseGuardian.NotOperator.selector);
        g.setPaused(true);
    }
}
