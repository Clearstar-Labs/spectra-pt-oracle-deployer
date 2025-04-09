// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVaultV2 {
    function getPricePerFullShare() external view returns (uint256);
}