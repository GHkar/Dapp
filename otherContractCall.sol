// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma

interface otherContract{
    function getData() external view returns(uint);
    function value() external view returns(uint);
    function setData(uint _value) external;
}

// (2) Declare Contract
contract AnotherContractCall {
        otherContract oc;
        constructor (address o) {
            oc = otherContract(o);
        }

        function g1() public view returns(uint){
            return oc.getData();
        }

        function g2() public view returns(uint){
            return oc.value();
        }

        function s(uint _value) public{
            oc.setData(_value);
        }
}
