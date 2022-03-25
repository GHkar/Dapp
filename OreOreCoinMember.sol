// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma

// 소유자 관리용 계약
contract Owned{
    address public owner;

    event TransferOwnership(address oldaddr, address newaddr);

    modifier onlyOwner() {if(msg.sender != owner) revert(); _;}

    constructor(){
        owner = msg.sender;
    }

    function transferOwnership(address _new) onlyOwner public {
        address oldaddr = owner;
        owner = _new;
        emit TransferOwnership(oldaddr, owner);
    }
}

// 회원 관리용 계약
contract Members is Owned {
    address public coin; // 토큰 주소
    MemberStatus[] public status; // 회원 등급 배열
    mapping(address => History) public tradingHistory; // 회원별 거래 이력

    // 회원 등급용 구조체
    struct MemberStatus{
        string name; // 등급 이름
        uint256 times; // 해당 등급의 최저 거래 횟수
        uint256 sum; // 해당 등급의 최저 거래 금액
        int8 rate; // 캐시백 비율
    }

    // 거래 이력용 구조체
    struct History {
        uint256 times; // 거래 횟수
        uint256 sum; // 거래 금액
        uint256 statusIndex; // 등급 인덱스 = 어떤 등급의 회원인지 확인
    }

    // 토큰 한정 메서드용 수정자
    modifier onlyCoin() {if (msg.sender == coin) _;}
    
    // 토큰 주소 설정
    function setCoin(address _addr) onlyOwner public {
        coin = _addr;
    }

    // 회원 등급 추가
    function pushStatus(string memory _name, uint256 _times, uint256 _sum, int8 _rate) onlyOwner public{
        status.push(MemberStatus({
            name: _name,
            times: _times,
            sum: _sum,
            rate: _rate
        }));
    }

    // 회원 등급 내용 변경
    function editStatus(uint256 _index, string memory _name, uint256 _times, uint256 _sum, int8 _rate) onlyOwner public {
        if(_index < status.length)
        {
            status[_index].name = _name;
            status[_index].times = _times;
            status[_index].sum = _sum;
            status[_index].rate = _rate;
        }
    }

    // 거래 내역 갱신
    function updateHistory(address _member, uint256 _value) onlyCoin public{
        tradingHistory[_member].times += 1;
        tradingHistory[_member].sum += _value;
        // 새로운 회원 등급 결정
        uint256 index;
        int8 tmprate;
        for(uint i = 0; i < status.length; i++)
        {
            // 최저 거래 횟수, 최저 거래 금액 충족 시 가장 캐시백 비율이 좋은 등급으로 설정
            if (tradingHistory[_member].times >= status[i].times && tradingHistory[_member].sum >= status[i].sum && tmprate < status[i].rate){
                index = i;
            }
        }
        tradingHistory[_member].statusIndex = index;
    }


    // 캐시백 비율 획득 (회원의 등급에 해당하는 비율 확인)
    function getCashbackRate(address _member) view public returns (int8 rate) {
        rate = status[tradingHistory[_member].statusIndex].rate;
    }

}


// 블랙리스트 기능을 추가한 가상 화폐
contract OreOreCoin is Owned{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => int8) public blackList;
    mapping (address => Members) public members;

    // 이벤트 알림
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Blacklisted(address indexed target);
    event DeleteFromBlacklist(address indexed target);
    event RejectedPaymentToBlacklistAddr(address indexed from, address indexed to, uint256 value);
    event RejectedPaymentFromBlacklistAddr(address indexed from, address indexed to, uint256 value);
    event Cashback(address indexed from, address indexed to, uint256 value);

    // 생성자
    constructor (uint256 _supply, string memory _name, string memory _symbol, uint8 _decimals) {
        balanceOf[msg.sender] = _supply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply;
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

    // 회원 관리 계약 설정
    function setMembers(Members _members) public{
        members[msg.sender] = Members(_members);
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
            if(address(members[_to]) != address(0))
            {
                cashback = _value / 100 * uint256(uint8(members[_to].getCashbackRate(msg.sender)));
                members[_to].updateHistory(msg.sender, _value);
            }

            balanceOf[msg.sender] -= (_value - cashback);
            balanceOf[_to] += (_value - cashback);

            emit Transfer(msg.sender, _to, _value);
            emit Cashback(_to, msg.sender, cashback);
        }
    }
}

