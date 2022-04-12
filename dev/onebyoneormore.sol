// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma
// (2) Declare Contract
contract onebyone {
        address public agent;       //개시자
        string public contents;     //모임내용
        uint256 public deadline;    //기한
        uint256 public goalNum;     //목표인원
        uint256 public fee;         //참가비
        mapping (address => bool) public member;    //멤버인지
        address[] public members;   //멤버주소
        

        modifier isdeadline() {if(deadline > block.timestamp)_;}

        event joining(address indexed mem);

        constructor(string memory _contents, uint256 _goalNum, uint256 _deadline, uint256 _fee) {
            agent = msg.sender;
            contents = _contents;
            deadline = block.timestamp + _deadline * 1 minutes;
            fee = _fee * 1 ether;
            goalNum = _goalNum;
        }

        function getInfo() public view returns (address _agent, string memory _contents, uint256 _deadline, uint256 _goalNum, uint256 _fee, address[] memory _members) {
            _agent = agent;
            _contents = contents;
            _deadline = deadline;
            _goalNum = goalNum;
            _fee = fee;
            _members = members;
        }

        function nowNum() public view returns (uint256 number){
            number = members.length;
        }

        function remain() public view returns (uint256 min){
            if(block.timestamp < deadline)
            {
                min = (deadline - block.timestamp) / (1 minutes);
            }
        }

        receive() external payable isdeadline {
            require(msg.value == fee && goalNum > members.length);
            member[msg.sender] = true;
            members.push(msg.sender);
            emit joining(msg.sender);
        }
}


// 데드라인을 날짜에 맞춰서 걸치는 애들을 모음
contract onebymore {
    address public admin;
    string public time; // 날짜 202204121400 sha256 값
    mapping(address => CA) public calist;
    uint256 public endTime;

    struct CA{
        string contents;     //모임내용
        uint256 deadline;    //기한
        uint256 goalNum;     //목표인원
        uint256 fee;         //참가비
        mapping (address => bool) member;    //멤버인지
        address[] members;   //멤버주소
    }

    modifier isAdmin() {if(msg.sender == admin)_;}
    modifier isEnd() {if(endTime > block.timestamp)_;}

    event joining(address indexed agent, address indexed mem);

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

    function remain(address _agent) public view returns (uint256 min){
        if(block.timestamp < calist[_agent].deadline)
        {   
            min = (calist[_agent].deadline - block.timestamp) / (1 minutes);
        }
    }

    function nowNum(address _agent) public view returns (uint256 number){
        number = calist[_agent].members.length;
    }

    function join(address _agent) external payable isEnd{
        CA storage nowCA = calist[_agent];        
        require(nowCA.deadline > block.timestamp);
        require(msg.value == nowCA.fee && nowCA.goalNum > nowCA.members.length);

        nowCA.member[msg.sender] = true;
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
