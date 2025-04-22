// SPDX-License-Identifier:
pragma solidity ^0.8.22;

interface IPrincipalToken {
    function getIBTRate() external view returns (uint256);
    function maturity() external view returns (uint256);
    function decimals() external view returns (uint8);
    function convertToUnderlying(uint256 principalAmount) external view returns (uint256);
    function underlying() external view returns (address);
}