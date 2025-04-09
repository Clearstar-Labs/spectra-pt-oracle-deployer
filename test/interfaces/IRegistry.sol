// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRegistry {
    function pTCount() external view returns (uint256);
    function getPTAt(uint256 _index) external view returns (address);
}