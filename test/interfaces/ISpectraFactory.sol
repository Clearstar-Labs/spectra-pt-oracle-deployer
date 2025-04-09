// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISpectraFactory {
    /**
     * @notice Getter for the registry address.
     * @return The address of the registry
     */
    function getRegistry() external view returns (address);

    /**
     * @notice Getter for the Curve Address Provider address
     * @return The address of the Curve Address Provider
     */
    function getCurveAddressProvider() external view returns (address);
}