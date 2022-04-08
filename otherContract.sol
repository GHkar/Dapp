// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma
// (2) Declare Contract
contract AnotherContract {
        uint public value = 10;

        function getData() public view returns (uint){
            return value;
        }

        function setData(uint _value) public{
            value = _value;
        }
}
