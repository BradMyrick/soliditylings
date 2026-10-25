// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// calldata1
// `calldata` is the cheapest location: it is a read-only view straight
// into the transaction's input data. No bytes get copied. For an
// EXTERNAL function that doesn't mutate its array/string arguments,
// calldata is the professional default — it's a gas optimization
// auditors look for.
//
// Below, the internal `_hash` helper insists on `bytes calldata` — and
// Solidity will not implicitly convert `memory` to `calldata` (there is
// no way to fake call data that isn't there). So the public function's
// parameter has exactly one legal location.
//
// TODO: Change `processInput` so its parameter can be passed to
// `_hash` — declare it as `calldata` and make it `external`.

import "forge-std/Test.sol";

contract Calldata1 {
    // Fixed helper: only accepts calldata.
    function _hash(bytes calldata input) internal pure returns (bytes32) {
        return keccak256(input);
    }

    // TODO: make this parameter calldata-compatible with _hash
    function processInput(bytes memory input) public pure returns (bytes32) {
        return _hash(input);
    }
}

contract Calldata1Test is Test {
    Calldata1 target;

    function setUp() public {
        target = new Calldata1();
    }

    function testProcessInput() public {
        bytes memory data = bytes("hello");
        assertEq(target.processInput(data), keccak256(data));
    }
}
