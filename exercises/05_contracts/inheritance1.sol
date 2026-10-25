// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// inheritance1
// Inheritance: `contract Dog is Animal`. A parent function must be
// marked `virtual` to allow overriding, and the override must match the
// signature and be marked `override`.
//
// The payoff is polymorphism: a `Dog` IS an `Animal`, so you can treat
// it as one — and the override still fires. The test relies on that.
//
// TODO: 1. Make `Dog` inherit from `Animal`.
//       2. Override `speak` to return "Woof!".

import "forge-std/Test.sol";

contract Animal {
    function speak() public pure virtual returns (string memory) {
        return "...";
    }
}

// TODO: inherit from Animal
contract Dog {
    // TODO: override speak()
}

contract Inheritance1Test is Test {
    function testDogSpeaks() public {
        Dog dog = new Dog();
        assertEq(dog.speak(), "Woof!");
    }

    function testPolymorphism() public {
        // A Dog can be stored in an Animal variable — virtual dispatch
        // still calls the override.
        Animal animal = new Dog();
        assertEq(animal.speak(), "Woof!", "the Dog override must fire");
    }
}
