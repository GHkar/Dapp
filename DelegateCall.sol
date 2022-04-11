// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma

contract Sample1 {
    uint public t;

    constructor() {}

    event L(uint a, uint b, address c);

    function test(uint a, uint b) public returns(uint)
    {
        t = a + b;
        emit L(a,b,msg.sender);
        return a + b;
    }
}

contract Sample2 {
    uint public t;

    constructor() {}

    // 그냥 call은 호출하면 호출한 스마트컨트랙의 변수값을 변경함
    function callTest(address contractAddr, uint to, uint value) public returns(bool, bytes memory, address)
    {
        (bool success, bytes memory data) = address(contractAddr).call(abi.encodeWithSignature("test(uint256,uint256)", to, value));
        
        if(!success){
            revert();
        }
        return (success, data, contractAddr);
    }
    
    // delegatecall은 함수를 호출하여 본인 스마트 컨트랙트 값 내의 변수를 변경함
    function delegatecallTest(address contractAddr, uint to, uint value) public returns (bool, bytes memory, address){
        (bool success, bytes memory data) = address(contractAddr).delegatecall(abi.encodeWithSignature("test(uint256,uint256)", to, value));

        if(!success){
            revert();
        }
        return (success, data, contractAddr);
    }
}
