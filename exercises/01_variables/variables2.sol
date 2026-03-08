// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// variables2.sol
// Make me compile!

contract Variables2 {
    // TODO: Address variables are very common in Solidity.
    // Declare a state variable `owner` of type `address` and make it public.

    constructor() {
        // Initialize owner to the deployer of the contract
        owner = msg.sender;
    }
}
