// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // (1) version pragma

contract Owned {
    modifier only_owner { if (msg.sender != owner) return; _; }

    event NewOwner(address indexed old, address indexed current);

    function setOwner(address _new) only_owner public { emit NewOwner(owner, _new); owner = _new; }

    address public owner = msg.sender;
}




