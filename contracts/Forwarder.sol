// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "hardhat/console.sol";

contract Wallet {
    address public immutable forwarder;

    constructor(address _forwarder) payable {
        require(msg.value == 1 ether);
        forwarder = _forwarder;
    }

    function sendEther(address destination, uint256 amount) public {
        console.log("sendEther entered");
        require(msg.sender == forwarder, "sender must be forwarder contract");
        console.log("balance of this wallet:", address(this).balance);
        console.log("require passed");
        console.log("destination:", destination);
        console.log("amount:", amount);
        (bool success,) = destination.call{value: amount}("");
        require(success, "failed");
        console.log("success sendEther:", success);
        console.log("after transfer wallet balance:", address(this).balance);
    }
}

contract Forwarder {
    function functionCall(address a, bytes calldata data) public {
        console.log("functionCall entered");
        (bool success,) = a.call(data);
        require(success, "forward failed");
    }
}
