// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma

// 블랙리스트 기능을 추가한 가상 화폐
contract OreOreCoin {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => int8) public blackList;
    mapping (address => int8) public cashbackRate;
    address public owner;

    // 수정자
    modifier onlyOwner() { if (msg.sender != owner) revert(); _;}

    // 이벤트 알림
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Blacklisted(address indexed target);
    event DeleteFromBlacklist(address indexed target);
    event RejectedPaymentToBlacklistAddr(address indexed from, address indexed to, uint256 value);
    event RejectedPaymentFromBlacklistAddr(address indexed from, address indexed to, uint256 value);
    event SetCashback(address indexed addr, int8 rate);
    event Cashback(address indexed from, address indexed to, uint256 value);

    // 생성자
    constructor (uint256 _supply, string memory _name, string memory _symbol, uint8 _decimals) {
        balanceOf[msg.sender] = _supply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply;
        owner = msg.sender; // 소유자 주소 설정
    }

    // 주소를 블랙리스트에 등록
    function blacklisting(address _addr) onlyOwner public {
        blackList[_addr] = 1;
        emit Blacklisted(_addr);
    }

    // 주소를 블랙리스트에서 제거
    function deleteFromBlacklist(address _addr) onlyOwner public {
        blackList[_addr] = -1;
        emit DeleteFromBlacklist(_addr);
    }

    // 캐시백 비율 설정
    function setCashbackRate(int8 _rate) public{
        if(_rate < 1){
            _rate = -1;
        }
        else if(_rate > 100){
            _rate = 100;
        }

        cashbackRate[msg.sender] = _rate;
        if(_rate < 1){
            _rate = 0;
        }
        emit SetCashback(msg.sender, _rate);
    }

    // 송금
    function transfer(address _to, uint256 _value) public {
        // 부정 송금 확인
        require(balanceOf[msg.sender] > _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // 블랙리스트에 존재하는 주소는 입출금 불가
        if(blackList[msg.sender] > 0)
        {
            emit RejectedPaymentFromBlacklistAddr(msg.sender, _to, _value);
        }
        else if(blackList[_to] > 0)
        {
            emit RejectedPaymentToBlacklistAddr(msg.sender, _to, _value);
        }
        else{
            //캐시백 금액 계산
            uint256 cashback = 0;
            if(cashbackRate[_to] > 0) cashback = _value / 100 * uint256(uint8(cashbackRate[_to]));

            balanceOf[msg.sender] -= (_value - cashback);
            balanceOf[_to] += (_value - cashback);

            emit Transfer(msg.sender, _to, _value);
            emit Cashback(_to, msg.sender, cashback);
        }
    }
}

