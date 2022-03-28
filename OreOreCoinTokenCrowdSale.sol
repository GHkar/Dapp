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


// 크라우드 세일
contract Crowdsale is Owned {
    // 상태 변수
    uint256 public fundingGoal; // 목표 금액
    uint256 public deadline; // 기한
    uint256 public price; // 토큰 기본 가격
    uint256 public transferableToken; // 전송 가능 토큰
    uint256 public soldToken; // 판매된 토큰
    uint256 public startTime; // 개시 시간
    OreOreCoin public tokenReward; // 지불에 사용할 토큰
    bool public fundingGoalReached; // 목표 도달 플래그
    bool public isOpened; // 크라우드 세일 개시 플래그
    mapping (address => Property) public fundersProperty; //자금 제공자의 자산 정보

    // 자산 정보 구조체
    struct Property {
        uint256 paymentEther; // 지불한 Ether
        uint256 reservedToken; // 받은 토큰
        bool withdrawed; // 인출 플래그
    }

    // 이벤트 알림
    event CrowdsaleStart(uint fundingGoal, uint deadline, uint transferableToken, address beneficiary);
    event ReservedToken(address backer, uint amount, uint token);
    event CheckGoalReached(address beneficiary, uint fundingGoal, uint amountRaised, bool reached, uint raisedToken);
    event WithdrawalToken(address addr, uint amount, bool result);
    event WithdrawalEther(address addr, uint amount, bool result);

    // 수정자
    modifier afterDeadline() {if(block.timestamp >= deadline) _;}

    // 생성자
    constructor (
        uint _fundingGoalInEthers,
        uint _transferableToken,
        uint _amountOfTokenPerEther,
        OreOreCoin _addressOfTokenUsedAsReward
    ){
        fundingGoal = _fundingGoalInEthers * 1 ether;
        price = 1 ether / _amountOfTokenPerEther;
        transferableToken = _transferableToken;
        tokenReward = OreOreCoin(_addressOfTokenUsedAsReward);
    }

    // 이름 없는 함수 (ether 받기)
    receive() external payable {
        // 개시 전 또는 기간이 지난 경우 예외 처리
        require(isOpened || block.timestamp <= deadline);

        // 받은 Ether와 판매 예정 토큰
        uint amount = msg.value;
        uint token = amount / price * (100 + currentSwapRate()) / 100;

        // 판매 예정 토큰의 확인(예정 수를 초과하는 경우는 예외 처리)
        require(token != 0 || soldToken + token < transferableToken);

        // 자산 제공자의 자산 정보 변경
        fundersProperty[msg.sender].paymentEther += amount;
        fundersProperty[msg.sender].reservedToken += token;
        soldToken += token;
        emit ReservedToken(msg.sender, amount, token);
    }

    // 개시(토큰이 예정한 수 이상 있다면 개시)
    function start(uint _durationInMinutes) onlyOwner public {
        if(fundingGoal == 0 || price == 0 || transferableToken == 0 || address(tokenReward) == address(0) || _durationInMinutes == 0 || startTime != 0)
        {
            revert();
        }
        if (tokenReward.balanceOf(address(this)) >= transferableToken)
        {
            startTime = block.timestamp;
            deadline = block.timestamp + _durationInMinutes * 1 minutes;
            isOpened = true;
            emit CrowdsaleStart(fundingGoal, deadline, transferableToken, owner);
        }
    }

    // 교환 비율(개시 시작부터 시간이 적게 경과할수록 더 많은 보상)
    function currentSwapRate() view public returns(uint) {
        if(startTime + 3 minutes > block.timestamp)
        {
            return 100;
        }
        else if (startTime + 5 minutes > block.timestamp)
        {
            return 50;
        }
        else if (startTime + 10 minutes > block.timestamp)
        {
            return 20;
        }
        else{
            return 0;
        }
    }

    // 남은 시간(분 단위)과 목표와의 차이(eth 단위), 토큰 확인용 메서드
    function getRemainingTimeEthToken() view public returns(uint min, uint shortage, uint remainToken)
    {
        if(block.timestamp < deadline)
        {
            min = (deadline - block.timestamp) / (1 minutes);
        }
        shortage = (fundingGoal - address(this).balance) / (1 ether);
        remainToken = transferableToken - soldToken;
    }

    // 목표 도달 확인(기한 후 실시 가능)
    function checkGoalReached() afterDeadline public {
        if (isOpened)
        {
            // 모인 Ether와 목표 Ether 비교
            if (address(this).balance >= fundingGoal)
            {
                fundingGoalReached = true;
            }
            isOpened = false;
            emit CheckGoalReached(owner, fundingGoal, address(this).balance, fundingGoalReached, soldToken);
        }
    }

    // 소유자용 인출 메서드 (판매 종료 후 실시 가능)
    function withdrawalOwner() onlyOwner public {
        if(isOpened) revert();
        // 목표 달성 : Ether와 남은 토큰. 목표 미달 : 토큰
        if(fundingGoalReached){
            // 모금된 Ether
            uint amount = address(this).balance;
            if (amount > 0){
                (bool ok, ) = msg.sender.call{value:amount}("");
                emit WithdrawalEther(msg.sender, amount, ok);
            }

            // 남은 토큰
            uint val = transferableToken - soldToken;
            if (val > 0)
            {
                tokenReward.transfer(msg.sender, transferableToken - soldToken);
                emit WithdrawalToken(msg.sender, val, true);
            }
        }
        else{
            // 토큰
            uint val2 = tokenReward.balanceOf(address(this));
            tokenReward.transfer(msg.sender, val2);
            emit WithdrawalToken(msg.sender, val2, true);
        }
    }

    // 자금 제공자용 인출 메서드 (세일 종료 후 실시 가능)
    function withdrawal() public{
        if (isOpened) return;
        // 이미 인출된 경우 예외 처리
        if (fundersProperty[msg.sender].withdrawed) revert();
        // 목표 달성 : 토큰, 목표 미달 : Ether
        if (fundingGoalReached) {
            if(fundersProperty[msg.sender].reservedToken > 0){
                tokenReward.transfer(msg.sender, fundersProperty[msg.sender].reservedToken);
                fundersProperty[msg.sender].withdrawed = true;
                emit WithdrawalToken(
                    msg.sender, fundersProperty[msg.sender].reservedToken, fundersProperty[msg.sender].withdrawed
                );
            }
        }
        else{
            if (fundersProperty[msg.sender].paymentEther > 0)
            {
                (bool isok, ) = msg.sender.call{value : fundersProperty[msg.sender].paymentEther}("");
                if(isok){
                    fundersProperty[msg.sender].withdrawed = true;
                }
            }
            emit WithdrawalEther(
                msg.sender,
                fundersProperty[msg.sender].paymentEther,
                fundersProperty[msg.sender].withdrawed
            );
        }
    }

}
