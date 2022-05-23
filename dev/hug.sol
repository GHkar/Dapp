// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; 

contract hug {
    address public admin;   // 관리자
    string public time;     // 발행 시간
    mapping(address => CA) public calist;   // 모임 목록
    uint256 public endTime; // 끝나는 시간

    struct CA{
        string contents;    // 컨텐츠(html의 body 중 일부 section div, p를 의미)
        uint256 deadline;   // 목표 기간
        uint256 goalNum;    // 모임 목표 인원
        uint256 fee;        // 목표 요금
        bool butgo;         // 조건 미충족시 모임 수행 여부
        address[] members;  // 참여 인원
    }

    modifier isAdmin() {if(msg.sender == admin)_;}
    modifier isEnd() {if(endTime > block.timestamp)_;}


    event joining(address indexed agent, address indexed mem);  // 모임에 참가
    event addcontract(address indexed agent);                   // 모임이 발행

    constructor(string memory _time) {
        admin = msg.sender;
        time = _time;
        endTime = block.timestamp + 10 * 1 minutes;
    }

    function addCa(address _agent, string memory _contents, uint256 _goalNum, uint256 _deadline, uint256 _fee) public isAdmin {
        CA storage tmpca = calist[_agent];
        tmpca.contents = _contents;
        tmpca.deadline = block.timestamp + _deadline * 1 minutes;
        tmpca.goalNum = _goalNum;
        tmpca.fee = _fee * 1 ether;
    }

    function remain(address _agent) public view returns (uint256 min, uint256 num){
        if(block.timestamp < calist[_agent].deadline)
        {   
            min = (calist[_agent].deadline - block.timestamp) / (1 minutes);
            num = (calist[_agent].goalNum - calist[_agent].members.length);
        }
    }

    function nowNum(address _agent) public view returns (uint256 number){
        number = calist[_agent].members.length;
    }

    function join(address _agent) external payable isEnd{
        CA storage nowCA = calist[_agent];        
        require(nowCA.deadline > block.timestamp);
        require(msg.value == nowCA.fee && nowCA.goalNum > nowCA.members.length);

        nowCA.members.push(msg.sender);
        emit joining(_agent, msg.sender);   
    }

    function getInfo(address _agent) public view returns (string memory _contents, uint256 _deadline, uint256 _goalNum, uint256 _fee, address[] memory _members) {
        CA storage tmpCA = calist[_agent];
        _contents = tmpCA.contents;
        _deadline = tmpCA.deadline;
        _goalNum = tmpCA.goalNum;
        _fee = tmpCA.fee;
        _members = tmpCA.members;
    }
}
