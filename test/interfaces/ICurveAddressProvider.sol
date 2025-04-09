// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ICurveAddressProvider {
    function get_address(uint256 _id) external view returns (address);
}