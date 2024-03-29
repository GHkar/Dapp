// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma
// (2) Declare Contract
contract Ballot {
    struct Voter {
        uint weight;
        bool voted;
        uint vote;
    }

    struct Proposal {
        uint voteCount;
    }

    address chairperson;
    mapping(address => Voter) voters;
    Proposal[] proposals;

    enum Phase{Init, Regs, Vote, Done}
    Phase public state = Phase.Init;

    modifier validPhase(Phase reqPhase){
        require(state == reqPhase);
        _;
    }

    modifier onlyChair(){
        require(msg.sender == chairperson);
        _;
    }

    constructor (uint numProposals){
        chairperson = msg.sender;
        voters[chairperson].weight = 2;
        for(uint prop = 0; prop < numProposals; prop ++)
        {
            proposals.push(Proposal(0));
            state = Phase.Regs;
        }
    }

    function changeState(Phase x) public onlyChair {
        require(x>state);
        state = x;
    }

    function register(address voter) public validPhase(Phase.Regs) onlyChair {
        require(!voters[voter].voted);
        voters[voter].weight = 1;
        voters[voter].voted = false;
    }

    function vote(uint toProposal) public validPhase(Phase.Vote){
        Voter memory sender = voters[msg.sender];
        require(!sender.voted);
        require(toProposal < proposals.length);
        sender.voted = true;
        sender.vote = toProposal;
        //HYPERLINK "http://sender.vote/"sender.vote = toProposal;
        proposals[toProposal].voteCount += sender.weight;
    }

    function reqWinner() public validPhase(Phase.Done) view returns (uint winningProposal){
        uint winningVoteCount = 0;
        for (uint prop = 0; prop < proposals.length; prop++){
            if(proposals[prop].voteCount > winningVoteCount){
                winningVoteCount = proposals[prop].voteCount;
                winningProposal = prop;
            }
        }
        assert(winningVoteCount>=3);
    }


}
