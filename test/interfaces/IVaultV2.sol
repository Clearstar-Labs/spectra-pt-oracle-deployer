// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

interface IVaultV2 {
    function getPricePerFullShare() external view returns (uint256);
    function deploymentTimestamp() external view returns (uint256);
}