// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma

// (2) Declare Contract
contract HelloWorld {
        // (3) Declare state word
        string public greeting;
        // (4) producer
        constructor (string memory g){
                greeting = g;
        }
        // (5) Declare method
        function setGreeting(string memory g) public {
                greeting = g;
        }
        function say() public view returns(string memory) {
                return greeting;
        }
}
