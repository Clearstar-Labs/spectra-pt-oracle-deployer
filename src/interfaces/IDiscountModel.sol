// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IDiscountModel {
    /**
     * @notice Computes the price for a given principal token.
     * @dev This function can be implemented customly, so not all argumnets need to be used
     *
     * @param initialImpliedAPY The initial implied APY of the principal token (in 18 decimals).
     * @param timeLeft The time remaining until maturity, in seconds.
     * @param futurePTValue The future value of the principal token at maturity.
     * @param underlyingUnit The unit of the underlying asset.
     * @return price The computed price, expressed with futurePTValue's decimals precision.
     */
    function getPrice(
        uint256 initialImpliedAPY,
        uint256 timeLeft,
        uint256 futurePTValue,
        uint256 underlyingUnit
    ) external pure returns (uint256 price);

    /**
     * @notice Returns a human-readable description of the discount model.
     * @return A string describing the discount model.
     */
    function description() external pure returns (string memory);
}