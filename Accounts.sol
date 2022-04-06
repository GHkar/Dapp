// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma
// (2) Declare Contract
contract AccountDemo {
        // (3) Declare state word
        address public whoDeposited;
        uint public depositAmt;
        uint public accountBalance;

        // (4) producer
        // (5) Declare method
        function deposit() public payable {
            whoDeposited = msg.sender;
            depositAmt = msg.value;
            accountBalance = address(this).balance;
        }
}
