// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPrincipalToken} from "../interfaces/IPrincipalToken.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

contract APYCalculator is Test {
    uint256 private constant UNIT = 1e18;
    uint256 private constant SECONDS_PER_YEAR = 365 days;
    uint256 private constant SECONDS_PER_DAY = 1 days;
    uint256 private constant BLOCKS_PER_DAY = 43_200;
    uint256 private constant DAYS_TO_LOOK_BACK = 1;
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
    ) private pure returns (uint256) {
        // First convert timeToMaturity to years to avoid overflow
        uint256 timeToMaturityScaled = (timeToMaturity * UNIT) / SECONDS_PER_YEAR;
        
        // Calculate the discount
        uint256 discount = UNIT - curveInitialPrice;
        
        // Calculate annualized rate: discount / timeInYears
        uint256 impliedAPY = (discount * UNIT) / timeToMaturityScaled;
        
        console.log("timeToMaturity (seconds):", timeToMaturity);
        console.log("Time to Maturity (scaled to 1e18):", timeToMaturityScaled);
        console.log("curve price:", curveInitialPrice);
        console.log("discount:", discount);
        console.log("implied APY:", impliedAPY);
        
        return impliedAPY;
    }

    function calculateInitialImpliedAPY(
        address pt,
        address curvePool,
        uint256 /* curveInitialPrice - not used anymore */
    ) external returns (uint256) {
        require(curvePool != address(0), "Curve pool not found");

        // Get current price from Curve pool (in IBT/PT terms)
        (bool success, bytes memory data) = curvePool.call(
            abi.encodeWithSignature("last_prices()")
        );
        require(success, "Failed to get current price");
        uint256 ibtPrice = abi.decode(data, (uint256));
        
        // Convert IBT price to underlying price using IBT's previewRedeem
        address ibt = IPrincipalToken(pt).getIBT();
        uint256 currentPrice = IERC4626(ibt).previewRedeem(ibtPrice);
        
        require(currentPrice >= MIN_CURVE_PRICE, "Curve price too low");
        require(currentPrice <= MAX_CURVE_PRICE, "Curve price too high");

        uint256 timeToMaturity = IPrincipalToken(pt).maturity() - block.timestamp;
        uint256 timeToMaturityScaled = (timeToMaturity * UNIT) / SECONDS_PER_YEAR;
        uint256 discount = UNIT - currentPrice;
        uint256 impliedAPY = (discount * UNIT) / timeToMaturityScaled;
        
        console.log("IBT/PT Curve Price:", ibtPrice);
        console.log("Underlying Price:", currentPrice);
        console.log("Time to Maturity (years):", timeToMaturityScaled);
        console.log("Discount:", discount);
        console.log("Implied APY:", impliedAPY);
        
        require(impliedAPY <= MAX_REASONABLE_APY, "APY too high");
        return impliedAPY;
    }
}
