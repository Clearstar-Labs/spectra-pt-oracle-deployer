// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
interface ISpectraPriceOracleFactory {
    function createOracle(
        address _pt,
        address _discountModel,
        uint256 initialImpliedAPY,
        address initOwner
    ) external returns (address);
}