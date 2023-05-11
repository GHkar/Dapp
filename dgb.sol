// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma

contract DGB {
    string public name; // 토큰 이름
    string public symbol; // 토큰 단위
    uint8 public decimals; // 소수점 이하 자리수
    uint256 public totalSupply; // 토큰 총량
    mapping (address => uint256) public balanceOf; // 각 주소의 잔고

    // 로그 찍어주기
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 생성자
    constructor (uint256 _supply) {
        balanceOf[msg.sender] = _supply;
        name = "DGB";
        symbol = "don";
        decimals = 0;
        totalSupply = _supply;
    }

    // 송금
    function transfer(address _to, uint256 _value) public {
        // 부정 송금 확인
        require(balanceOf[msg.sender] > _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // 송금하는 주소와 송금받는 주소의 잔고 갱신
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] +=_value;
        // 이벤트 알림
        emit Transfer(msg.sender, _to, _value);
        
    }
}
