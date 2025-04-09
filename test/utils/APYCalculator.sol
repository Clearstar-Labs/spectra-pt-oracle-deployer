// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import {IPrincipalToken} from "../interfaces/IPrincipalToken.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import {LogExpMath} from "./LogExpMath.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

contract APYCalculator is Test {
    uint256 private constant UNIT = 1e18;
    uint256 private constant SECONDS_PER_YEAR = 365 days;
    uint256 private constant SECONDS_PER_DAY = 1 days;
    uint256 private constant BLOCKS_PER_DAY = 43_200;
    uint256 private constant DAYS_TO_LOOK_BACK = 7;
    uint256 private constant MIN_CURVE_PRICE = 5e17;
    uint256 private constant MAX_CURVE_PRICE = 99e16;
    uint256 private constant MAX_REASONABLE_APY = 2e18;

    function calculateIBTYield(
        IVaultV2 vault,
        uint256 currentBlock
    ) private returns (uint256) {
        uint256 blocksToGoBack = BLOCKS_PER_DAY * DAYS_TO_LOOK_BACK;
        uint256 pastBlock = currentBlock - blocksToGoBack;
        
        uint256 currentPricePerShare = vault.getPricePerFullShare();
        
        uint256 forkId = vm.createFork(vm.envString("BASE_RPC_URL"), pastBlock);
        vm.selectFork(forkId);
        uint256 pastPricePerShare = vault.getPricePerFullShare();
        
        console.log("Current price per share:", currentPricePerShare);
        console.log("Past price per share:", pastPricePerShare);
        
        return ((currentPricePerShare - pastPricePerShare) * SECONDS_PER_YEAR * UNIT) 
               / (pastPricePerShare * (DAYS_TO_LOOK_BACK * SECONDS_PER_DAY));
    }

    function calculateFixedRate(
        uint256 timeToMaturity,
        uint256 curveInitialPrice
    ) private view returns (uint256) {
        uint256 timeToMaturityInYears = (timeToMaturity * UNIT) / SECONDS_PER_YEAR;
        
        // Calculate -ln(price)/t
        // The curve price is already in 1e18 scale
        int256 lnPrice = LogExpMath.ln(int256(curveInitialPrice));
        
        // Calculate -ln(price)/t and convert to yield
        // Multiply by UNIT first to maintain precision before division
        int256 ratePerYear = (-lnPrice * int256(UNIT)) / int256(timeToMaturityInYears) / 10;
        int256 yield = (LogExpMath.exp(ratePerYear) - int256(UNIT));
        
        console.log("timeToMaturity:", timeToMaturity);
        console.log("timeToMaturityInYears:", timeToMaturityInYears);
        console.log("curve price:", curveInitialPrice);
        console.log("ln(price):", uint256(-lnPrice));
        console.log("ratePerYear:", uint256(ratePerYear));
        console.log("yield:", uint256(yield));
        
        return uint256(yield > 0 ? yield : int256(0));
    }

    function calculateInitialImpliedAPY(
        address pt,
        uint256 curveInitialPrice
    ) external returns (uint256) {
        require(curveInitialPrice >= MIN_CURVE_PRICE, "Curve price too low");
        require(curveInitialPrice <= MAX_CURVE_PRICE, "Curve price too high");

        IPrincipalToken principalToken = IPrincipalToken(pt);
        IVaultV2 vault = IVaultV2(principalToken.getIBT());
        
        uint256 ibtYield = calculateIBTYield(vault, block.number);
        console.log("IBT Yield:", ibtYield);
        
        uint256 timeToMaturity = principalToken.maturity() - block.timestamp;
        uint256 fixedRate = calculateFixedRate(timeToMaturity, curveInitialPrice);
        
        uint256 finalRate = ibtYield > fixedRate ? ibtYield : fixedRate;
        require(finalRate <= MAX_REASONABLE_APY, "APY too high");
        
        return finalRate;
    }
}
