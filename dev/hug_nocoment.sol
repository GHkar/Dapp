// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; 

contract hug {
    address payable public admin;
    mapping(address => HUG) public huglist;
    bool public lock;

    struct HUG{
        string contents;
        uint256 deadline;
        uint256 openfee;
        uint256 goalNum;
        uint256 joinfee;
        address payable[] members;
    }

    modifier isAdmin() {if(msg.sender == admin)_;}
    modifier isLock() {if(lock == false)_;}

    event adding(address indexed agent, uint openfee);
    event joining(address indexed agent, address indexed member, uint joinfee);
    event refunding(address payable indexed addr, uint value);
    event result(address indexed agent, bool doit, bool butgo, address[] absentlist);

    constructor() {
        admin = payable(msg.sender);
        lock = false;
    }

    function locking(bool key) public isAdmin{
        lock = key;
    }

    function addHug(string memory _contents, uint256 _goalNum, uint256 _deadline, uint256 _joinfee) external payable isLock {
        require(msg.value >= 1 ether);

        HUG storage tmphug = huglist[msg.sender];
        tmphug.contents = _contents;
        tmphug.openfee = msg.value;
        tmphug.deadline = block.timestamp + _deadline * 1 minutes;
        tmphug.goalNum = _goalNum;
        tmphug.joinfee = _joinfee * 1 ether;

        emit adding(msg.sender, msg.value);
    }

    function join(address _agent) external payable isLock{
        HUG storage nowHUG = huglist[_agent];

        require(nowHUG.deadline > block.timestamp);
        require(msg.value == nowHUG.joinfee && nowHUG.goalNum > nowHUG.members.length);

        nowHUG.members.push(payable(msg.sender));

        emit joining(_agent, msg.sender, msg.value);
    }


    function reset(address payable _agent) public isAdmin isLock{
        delete huglist[_agent];
    }

    function refund(address payable _agent, bool doit, bool butgo, address[] memory absentlist, uint opengas, uint[] memory joingas) public isAdmin isLock{
        HUG storage nowHUG = huglist[_agent];        

        require(nowHUG.deadline < block.timestamp);

        uint forAgent;
        uint forMember;

        if(absentlist.length == 0)
        {
            if(doit)
            {   
                { 
                    forAgent = nowHUG.openfee - (nowHUG.openfee * 1/100);    
                    forMember = nowHUG.joinfee - (nowHUG.joinfee * 1/100);
                }
            }
            else 
            {
                forAgent = nowHUG.openfee;
                forMember = nowHUG.joinfee;
            }


            for(uint i = 0; i < nowHUG.members.length; i++)      
            {   
                uint tmpforMember = forMember - ( joingas[0] - joingas[i]);
                nowHUG.members[i].transfer(tmpforMember);
                emit refunding(nowHUG.members[i], tmpforMember);
            }

        }
        else 
        {   
            forAgent = nowHUG.openfee + opengas;
            forMember = nowHUG.joinfee;
            bool del;


            for(uint i = 0; i < nowHUG.members.length; i++)
            {   
                del = false;
                for(uint j = 0; j < absentlist.length; j++)
                {
                    if(nowHUG.members[i] == absentlist[j])
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
        
        _agent.transfer(forAgent);   
        emit refunding(_agent, forAgent);
    
            
        emit result(_agent, doit, butgo, absentlist);
        
        delete huglist[_agent];
    }

    function getBalance() public isAdmin isLock{
        emit refunding(admin, address(this).balance);
        admin.transfer(address(this).balance);
    }

    function remain(address _agent) public isLock view returns (uint256 min, uint256 num){
        if(block.timestamp < huglist[_agent].deadline)
        {   
            min = (huglist[_agent].deadline - block.timestamp) / (1 minutes);
            num = (huglist[_agent].goalNum - huglist[_agent].members.length);
        }
    }

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
