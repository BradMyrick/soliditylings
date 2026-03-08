// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// errors1.sol
// Make me compile!

contract Errors1 {
    // TODO: Define a custom error named `Unauthorized` that takes an `address caller`.
    

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function doSomethingRestricted() public {
        // TODO: Revert with the `Unauthorized` error (passing `msg.sender`)
        // if the caller is not the `owner`.
        
    }
}
