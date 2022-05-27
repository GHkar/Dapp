// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; 

contract hug {
    address payable public admin;   // 관리자
    mapping(address => HUG) public huglist;   // 모임 목록
    bool public lock;            // 점검 및 관리를 목적으로 컨트랙트를 잠그거나 풀 수 있음

    struct HUG{
        string contents;    // 컨텐츠(html의 body 중 일부 section div, p를 의미)
        uint256 deadline;   // 목표 기간
        uint256 openfee;    // 모임 개시 비용
        uint256 goalNum;    // 모임 목표 인원
        uint256 joinfee;    // 목표 요금
        address payable[] members;  // 참여 인원
    }

    modifier isAdmin() {if(msg.sender == admin)_;}  // 관리자인가
    modifier isLock() {if(lock == false)_;} // 잠금해제 상태면 수행

    event adding(address indexed agent, uint openfee);                                  // 모임 생성
    event joining(address indexed agent, address indexed member, uint joinfee);         // 모임에 참가
    event refunding(address payable indexed addr, uint value);                          // 모임 완료 후 돈 반환
    event result(address indexed agent, bool doit, bool butgo, address[] absentlist);   // 모임 결과

    constructor() {
        admin = payable(msg.sender);
        lock = false;
    }

    // 컨트랙트 잠금 및 해제
    function locking(bool key) public isAdmin{
        lock = key;
    }

    // 컨트랙트에 모임 추가
    function addHug(string memory _contents, uint256 _goalNum, uint256 _deadline, uint256 _joinfee) external payable isLock {
        require(msg.value >= 1 ether);      // 기본 요금 충족 필요

        HUG storage tmphug = huglist[msg.sender];
        tmphug.contents = _contents;
        tmphug.openfee = msg.value;
        tmphug.deadline = block.timestamp + _deadline * 1 minutes;
        tmphug.goalNum = _goalNum;
        tmphug.joinfee = _joinfee * 1 ether;

        emit adding(msg.sender, msg.value);
    }

    // 모임에 참가
    function join(address _agent) external payable isLock{
        HUG storage nowHUG = huglist[_agent];

        require(nowHUG.deadline > block.timestamp);                                          // 마감 기한
        require(msg.value == nowHUG.joinfee && nowHUG.goalNum > nowHUG.members.length);      // 목표 인원

        nowHUG.members.push(payable(msg.sender));

        emit joining(_agent, msg.sender, msg.value);
    }

    // 초기화 기능
    function reset(address payable _agent) public isAdmin isLock{
        delete huglist[_agent];
    }

    // 정상 수행 + 미수행 + 강제 수행 + 결석 인원 - 모임 돈 정산 + 초기화 기능 포함
    function refund(address payable _agent, bool doit, bool butgo, address[] memory absentlist, uint opengas, uint[] memory joingas) public isAdmin isLock{
        HUG storage nowHUG = huglist[_agent];        

        require(nowHUG.deadline < block.timestamp);       // 마감 기한이 끝났는가

        //uint agentToAdmin;      // 관리자에게 반환되는 돈
        uint forAgent;          // 모임장에게 반환되는 돈
        //uint memberToAdmin;     // 관리자에게 반환되는 돈
        uint forMember;         // 멤버에게 반환되는 돈
        // uint forAdmin;         // 관리자가 최종적으로 받는 돈

        if(absentlist.length == 0)
        {
            if(doit)    // 정상 수행 + 강제 수행
            {   
                {
                    //agentToAdmin = (nowHUG.openfee * 1/100);     
                    forAgent = nowHUG.openfee - (nowHUG.openfee * 1/100);    
                    //memberToAdmin = (nowHUG.joinfee * 1/100);
                    forMember = nowHUG.joinfee - (nowHUG.joinfee * 1/100);
                    //forAdmin = agentToAdmin + (memberToAdmin * nowHUG.members.length) + nowHUG.opengas;
                }
            }
            else        // 미수행
            {
                forAgent = nowHUG.openfee;
                forMember = nowHUG.joinfee;
                // forAdmin = nowHUG.opengas;
            }

            // 돈 송금
            for(uint i = 0; i < nowHUG.members.length; i++)    // 멤버         
            {   
                uint tmpforMember = forMember - ( joingas[0] - joingas[i]);
                nowHUG.members[i].transfer(tmpforMember);
                emit refunding(nowHUG.members[i], tmpforMember);
            }

        }
        else    // 결석 인원 발생 시
        {   
            forAgent = nowHUG.openfee + opengas;
            forMember = nowHUG.joinfee;
            bool del;

            // 돈 송금
            for(uint i = 0; i < nowHUG.members.length; i++)
            {   
                del = false;
                for(uint j = 0; j < absentlist.length; j++)
                {
                    if(nowHUG.members[i] == absentlist[j])      // 결석자를 제외
                    {
                        del = true;
                        break;
                    }
                }
                if(!del)
                {
                    uint tmpforMember = forMember + joingas[i];
                    nowHUG.members[i].transfer(tmpforMember);
                    emit refunding(nowHUG.members[i], tmpforMember);
                }
            }
        }
        
        // 돈 송금
        _agent.transfer(forAgent);                  // 모임장
        emit refunding(_agent, forAgent);
        
        //admin.transfer(forAdmin);                   // 관리자
        //emit refunding(admin, forAdmin);
            
        emit result(_agent, doit, butgo, absentlist);
        
        // 초기화
        delete huglist[_agent];
    }

    // 해당 컨트랙트에 남은 돈 전부 반환
    function getBalance() public isAdmin isLock{
        emit refunding(admin, address(this).balance);
        admin.transfer(address(this).balance);
    }

    
    // 남은 시간 계산
    function remain(address _agent) public isLock view returns (uint256 min, uint256 num){
        if(block.timestamp < huglist[_agent].deadline)
        {   
            min = (huglist[_agent].deadline - block.timestamp) / (1 minutes);
            num = (huglist[_agent].goalNum - huglist[_agent].members.length);
        }
    }

    // 정보 얻기
    function getInfo(address _agent) public isLock view returns (string memory _contents, uint256 _openfee, uint256 _deadline, uint256 _goalNum, uint256 _joinfee, address payable [] memory _members){
        HUG storage tmpHUG = huglist[_agent];

        _contents = tmpHUG.contents;
        _deadline = tmpHUG.deadline;
        _goalNum = tmpHUG.goalNum;
        _openfee = tmpHUG.openfee;
        _joinfee = tmpHUG.joinfee;
        _members = tmpHUG.members;
    }
}
