// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPrincipalToken} from "../interfaces/IPrincipalToken.sol";
import {IVaultV2} from "../interfaces/IVaultV2.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {LiquidityChecker} from "./LiquidityChecker.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";
import {LogExpMath} from "./LogExpMath.sol";

contract APYCalculator is Test {
    LiquidityChecker public liquidityChecker;

    constructor() {
        liquidityChecker = new LiquidityChecker();
    }

    uint256 private constant UNIT = 1e18;
    uint256 private constant SECONDS_PER_YEAR = 365 days;
    uint256 private constant SECONDS_PER_DAY = 1 days;
    uint256 private constant BLOCKS_PER_DAY = 43_200;
    uint256 private constant DAYS_TO_LOOK_BACK = 1;
    uint256 private constant MIN_CURVE_PRICE = 5e17;
    uint256 private constant MAX_CURVE_PRICE = 99e16;
    uint256 private constant MAX_REASONABLE_APY = 2e18;

    function calculateIBTYield(
        address vault
    ) external returns (uint256) {
        uint256 blocksToGoBack = BLOCKS_PER_DAY * DAYS_TO_LOOK_BACK;
        uint256 pastBlock = block.number - blocksToGoBack;
        
        // Get current price per share using ERC4626 standard functions
        uint256 currentPricePerShare = IERC4626(vault).previewRedeem(UNIT);
        
        uint256 forkId = vm.createFork(vm.envString("RPC_URL"), pastBlock);
        vm.selectFork(forkId);
        // Get past price per share using ERC4626 standard functions
        uint256 pastPricePerShare = IERC4626(vault).previewRedeem(UNIT);
        
        console.log("Current price per share:", currentPricePerShare);
        console.log("Past price per share:", pastPricePerShare);
        
        uint256 ibtYield = ((currentPricePerShare - pastPricePerShare) * SECONDS_PER_YEAR * UNIT) 
                          / (pastPricePerShare * (DAYS_TO_LOOK_BACK * SECONDS_PER_DAY));
        
        console.log("Estimated IBT yield (raw):", ibtYield);
        console.log("Estimated IBT yield (%):", _formatPercent(ibtYield));
        
        return ibtYield;
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

    function calculateImpliedAPY(
        IPrincipalToken pt,
        address curvePool
    ) external returns (uint256) {
        require(curvePool != address(0), "Curve pool not found");

        // Get prices and validate
        (uint256 ibtPrice, uint256 currentPrice) = _getPrices(pt, curvePool);
        require(currentPrice >= MIN_CURVE_PRICE, "Curve price too low");
        require(currentPrice <= MAX_CURVE_PRICE, "Curve price too high");

        // Calculate time and rates
        uint256 timeToMaturity = IPrincipalToken(pt).maturity() - block.timestamp;
        uint256 impliedAPY = _calculateAPY(currentPrice, timeToMaturity);
        uint256 impliedAPR = _calculateAPR(currentPrice, timeToMaturity);
        
        // Log values
        _logValues(ibtPrice, currentPrice, timeToMaturity, impliedAPR, impliedAPY);

        // Check pool liquidity
        liquidityChecker.checkPoolLiquidity(curvePool);
        
        require(impliedAPY <= MAX_REASONABLE_APY, "APY too high");
        return impliedAPY;
    }

    function _getPrices(IPrincipalToken pt, address curvePool) internal returns (uint256 ibtPrice, uint256 currentPrice) {
        // Get current price from Curve pool (in IBT/PT terms)
        (bool success, bytes memory data) = curvePool.call(
            abi.encodeWithSignature("price_oracle()")
        );
        require(success, "Failed to get current price");
        ibtPrice = abi.decode(data, (uint256));
        
        // Convert IBT price to underlying price using IBT's previewRedeem
        address ibt = IPrincipalToken(pt).getIBT();
        currentPrice = IERC4626(ibt).previewRedeem(ibtPrice);
    }

    function _calculateAPY(uint256 currentPrice, uint256 timeToMaturity) internal pure returns (uint256) {
        uint256 timeToMaturityScaled = (timeToMaturity * UNIT) / SECONDS_PER_YEAR;
        uint256 baseUint = (UNIT * UNIT) / currentPrice;
        require(baseUint > 0, "Base must be positive");
        int256 base = int256(baseUint);
        require(base > 0, "Negative base not allowed");

        int256 exponent = (int256(SECONDS_PER_YEAR) * int256(UNIT)) / int256(timeToMaturity);
        int256 ratePerSecond = LogExpMath.ln(base);
        int256 power = (ratePerSecond * exponent) / int256(UNIT);
        int256 result = LogExpMath.exp(power);
        return uint256(result - int256(UNIT));
    }

    function _calculateAPR(uint256 currentPrice, uint256 timeToMaturity) internal pure returns (uint256) {
        uint256 timeToMaturityScaled = (timeToMaturity * UNIT) / SECONDS_PER_YEAR;
        uint256 discount = UNIT - currentPrice;
        return (discount * UNIT) / timeToMaturityScaled;
    }

    function _logValues(
        uint256 ibtPrice, 
        uint256 currentPrice, 
        uint256 timeToMaturity,
        uint256 impliedAPR,
        uint256 impliedAPY
    ) internal pure {
        uint256 timeToMaturityScaled = (timeToMaturity * UNIT) / SECONDS_PER_YEAR;
        uint256 discount = UNIT - currentPrice;

        console.log("IBT/PT Curve Price (raw):", ibtPrice);
        console.log("IBT/PT Curve Price (decimal):", _formatDecimal(ibtPrice));
        console.log("Underlying Price (raw):", currentPrice);
        console.log("Underlying Price (decimal):", _formatDecimal(currentPrice));
        console.log("Time to Maturity in years (raw):", timeToMaturityScaled);
        console.log("Time to Maturity in years (decimal):", _formatDecimal(timeToMaturityScaled));
        console.log("Discount (raw):", discount);
        console.log("Discount (%):", _formatPercent(discount));
        console.log("Implied APR (raw):", impliedAPR);
        console.log("Implied APR (%):", _formatPercent(impliedAPR));
        console.log("Implied APY (raw):", impliedAPY);
        console.log("Implied APY (%):", _formatPercent(impliedAPY));
    }

    // Helper function to format decimals (18 decimals to 5 decimal places)
    function _formatDecimal(uint256 value) internal pure returns (string memory) {
        uint256 scaled = (value * 100000) / UNIT;
        uint256 whole = scaled / 100000;
        uint256 fraction = scaled % 100000;
        return string(abi.encodePacked(
            vm.toString(whole),
            ".",
            _padZeros(vm.toString(fraction), 5)
        ));
    }

    // Helper function to format percentage (18 decimals to 2 decimal places)
    function _formatPercent(uint256 value) internal pure returns (string memory) {
        uint256 scaled = (value * 10000) / UNIT;
        uint256 whole = scaled / 100;
        uint256 fraction = scaled % 100;
        return string(abi.encodePacked(
            vm.toString(whole),
            ".",
            _padZeros(vm.toString(fraction), 2),
            "%"
        ));
    }

    // Helper function to pad zeros
    function _padZeros(string memory s, uint256 length) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        bytes memory zeros = new bytes(length);
        for (uint i = 0; i < length; i++) {
            zeros[i] = "0";
        }
        if (b.length >= length) {
            return s;
        }
        bytes memory result = new bytes(length);
        uint256 padLength = length - b.length;
        for (uint i = 0; i < padLength; i++) {
            result[i] = "0";
        }
        for (uint i = 0; i < b.length; i++) {
            result[i + padLength] = b[i];
        }
        return string(result);
    }
}
