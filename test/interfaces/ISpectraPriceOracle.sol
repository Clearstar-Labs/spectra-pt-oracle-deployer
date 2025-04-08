// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISpectraPriceOracle {
    function PT() external view returns (address);
    function discountModel() external view returns (address);
    function initialImpliedAPY() external view returns (uint256);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}