// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma
// (2) Declare Contract
contract RecvEther {
        // (3) Declare state word
        address public sender;
        uint public recvEther;
        // (4) producer
        constructor() payable {
            sender = msg.sender;
            recvEther += msg.value;
        }
        // (5) Declare method
        receive() external payable { 
            sender = msg.sender;
            recvEther += msg.value;
        }
}
