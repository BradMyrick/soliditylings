// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Animal {
    function speak() public pure virtual returns (string memory) {
        return "...";
    }
}

contract Dog is Animal {
    function speak() public pure override returns (string memory) {
        return "Woof!";
    }
}

contract Inheritance1Test is Test {
    function testDogSpeaks() public {
        Dog dog = new Dog();
        assertEq(dog.speak(), "Woof!");
    }

    function testPolymorphism() public {
        Animal animal = new Dog();
        assertEq(animal.speak(), "Woof!", "the Dog override must fire");
    }
}
