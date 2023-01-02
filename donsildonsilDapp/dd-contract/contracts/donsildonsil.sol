// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; 

contract donsildonsil {
    address public admin;
    mapping(uint256 => Judge) public judgelist;
    uint256 public totalNum;

    struct Judge {                     
        string judgeType;
        uint256 judgeDate;
        bool pass;
        uint256 age;
        uint256 gender;
        uint256 salary;
        uint256 transactionNum;
        uint256 asset;
        uint256 creditPoint;
        uint256 loan;
        uint256 loanDate;
    }

    modifier isAdmin() {if(msg.sender == admin)_;}

    constructor() {
        admin = msg.sender;
        totalNum = 0;
    }

    function write(string memory _judgeType, uint256 _judgeDate, bool _pass, uint256 _age, uint256 _gender, uint256 _salary, uint256 _transactionNum, uint256 _asset, uint256 _loan, uint256 _loanDate) public isAdmin {
        totalNum += 1;
        Judge storage tmpjudge = judgelist[totalNum];
        tmpjudge.judgeType = _judgeType;
        tmpjudge.judgeDate = _judgeDate;
        tmpjudge.pass = _pass;
        tmpjudge.age = _age;
        tmpjudge.gender = _gender;
        tmpjudge.salary = _salary;
        tmpjudge.transactionNum = _transactionNum;
        tmpjudge.asset = _asset;
        tmpjudge.loan = _loan;
        tmpjudge.loanDate = _loanDate;
    }

    
    function show(uint _number) public view returns (string memory _judgeType, uint256 _judgeDate, bool _pass, uint256 _age, uint256 _gender, uint256 _salary, uint256 _transactionNum, uint256 _asset, uint256 _loan, uint256 _loanDate){
        Judge storage tmpjudge = judgelist[_number];
        _judgeType = tmpjudge.judgeType;
        _judgeDate = tmpjudge.judgeDate;
        _pass = tmpjudge.pass;
        _age = tmpjudge.age;
        _gender = tmpjudge.gender;
        _salary = tmpjudge.salary;
        _transactionNum = tmpjudge.transactionNum;
        _asset = tmpjudge.asset;
        _loan =  tmpjudge.loan;
        _loanDate =  tmpjudge.loanDate;
    }
}

