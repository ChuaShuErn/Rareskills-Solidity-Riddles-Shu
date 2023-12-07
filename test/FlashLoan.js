const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "FlashLoan tests";
const OneHundred_Ether = "0x56bc75e2d63100000";

describe(NAME, function () {
    async function setup() {
        const [owner, lender, borrower] = await ethers.getSigners();
        const TwentyEther = ethers.utils.parseEther("20");

        await network.provider.send("hardhat_setBalance", [
            lender.address,
            OneHundred_Ether, // 100 ether
        ]);

        // There are 3 people
        // owner, lender, borrower
        // lender has 100 ether

        const CollateralTokenFactory = await ethers.getContractFactory("CollateralToken");
        const collateralTokenContract = await CollateralTokenFactory.deploy();

        // Collateral Token

        // get AMM address before deployment as we call transferFrom in its constructor so it needs to be approved
        const createAddress =
            "0x" +
            ethers.utils
                .keccak256(
                    ethers.utils.RLP.encode([
                        owner.address,
                        ethers.utils.hexZeroPad(
                            (await ethers.provider.getTransactionCount(owner.address)) + 1
                            // + 1 because we approve first before deploying it
                        ),
                    ])
                )
                .slice(26);
        //"0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; contract address of AMM

        await collateralTokenContract.approve(createAddress, ethers.constants.MaxUint256);

        const AMMFactory = await ethers.getContractFactory("AMM");
        const AMMContract = await AMMFactory.deploy(collateralTokenContract.address, { value: TwentyEther });

        // AMM contract has a balance of 20 ether

        const LendingFactory = await ethers.getContractFactory("Lending");
        const LendingContract = await LendingFactory.deploy(AMMContract.address);

        const FlashLoanFactory = await ethers.getContractFactory("FlashLender");
        const FlashLoanContract = await FlashLoanFactory.deploy([collateralTokenContract.address], 0);

        // INIT FLASHLOAN CONTRACT: SEND 500 lend tokens to flashloan contract
        await collateralTokenContract.transfer(FlashLoanContract.address, ethers.utils.parseEther("500"));

        // owner deposits collateral to lending contract to be borrowable
        // can also be done by calling LendingContract.addLiquidity() but this is cheaper because no calldata to pay for
        console.log("owner about to deposit 6eth");
        await owner.sendTransaction({
            value: ethers.utils.parseEther("6"),
            to: LendingContract.address,
            data: "0x",
        });
        // owner gets no tokens..?
        // Ok so lending contract now has 6 eth...

        // Send 500 tokens to borrower for collateral
        await collateralTokenContract.transfer(borrower.address, ethers.utils.parseEther("500"));
        const tokenBalanceOfBorrow = await collateralTokenContract.balanceOf(borrower.address);
        console.log("tokenBalanceOfBorrower:", tokenBalanceOfBorrow);

        // Use borrower to approve lending contract
        await collateralTokenContract.connect(borrower).approve(LendingContract.address, ethers.constants.MaxUint256);

        // borrower takes loan and pays 240 tokens as collateral
        await LendingContract.connect(borrower).borrowEth(ethers.utils.parseEther("6"));
        const tokenBalanceOfBorrowAfterLoan = await collateralTokenContract.balanceOf(borrower.address);
        console.log("tokenBalanceOfBorrowerAfterLoan:", tokenBalanceOfBorrowAfterLoan);
        const tokenBalanceOfLendingContract = await collateralTokenContract.balanceOf(LendingContract.address);
        console.log("token balance of AMM after owner deposits 6 eth:", tokenBalanceOfLendingContract); // 240 e 18
        console.log("owner address:", owner.address);
        console.log("lender address:", lender.address);
        console.log("borrower address: ", borrower.address);
        console.log("lender in Lending Contract:", await LendingContract.lender()); // lender here is owner...

        // see the balances of all the contracts
        //tokenBalanceofLendingContract = 240e18
        return {
            FlashLoanContract,
            LendingContract,
            AMMContract,
            collateralTokenContract,
            borrower,
            lender,
        };
    }

    describe("exploit", async function () {
        let FlashLoanContract, LendingContract, AMMContract, collateralTokenContract, borrower, lender;

        before(async function () {
            ({ FlashLoanContract, LendingContract, AMMContract, collateralTokenContract, borrower, lender } =
                await loadFixture(setup));
        });

        // prettier-ignore
        it("conduct your attack here", async function () {
            const AttackerFactory = await ethers.getContractFactory("FlashLoanAttacker");
            const attackContract = await AttackerFactory.deploy(AMMContract.address, FlashLoanContract.address,collateralTokenContract.address, borrower.address, LendingContract.address);
            await attackContract.attack(lender.address);
           
    });

        after(async function () {
            /**
             * Requirements:
             * - Liquidate and take all collateral from lending contract and send to lender wallet
             * - Do this in 2 transactions or less?
             */
            const difference = (await collateralTokenContract.balanceOf(lender.address)).sub(
                ethers.utils.parseEther("240")
            ); // 240e18

            //lender balance must not be less than 210e18
            const pass = difference.gte(ethers.BigNumber.from(-30));

            expect(pass).to.be.equal(true, "Must take all of borrower's collateral");

            expect(await collateralTokenContract.balanceOf(LendingContract.address)).to.be.equal(
                0,
                "must fully drain lending contract"
            );

            expect(await ethers.provider.getTransactionCount(lender.address)).to.lessThan(
                3,
                "must exploit in two transactions or less"
            );
        });
    });
});
