// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// capstone2 — the deployment script + pause switch
// "Audits and releases: ... with deployment scripts, a pause switch
// and a recovery runbook alongside." Ship shape:
//
//   script/  — deterministic deploy under broadcast
//   tests    — a script's run() is just code: CALL it from a test and
//              assert the deployment came up healthy, pause included
//
// TODO: Complete `run` — deploy the PauseGuardian under broadcast and
// store it in `guardian`. (In a forge TEST, broadcast pranks from a
// deterministic sender; in `forge script` it signs and sends for real
// — the same code ships both ways.)

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

    // TODO: deploy under broadcast
    function run() external {
        guardian = new PauseGuardian(); // (currently deploys to the TEST context)
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

        // Whoever broadcast the deploy is the operator — act as them.
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
