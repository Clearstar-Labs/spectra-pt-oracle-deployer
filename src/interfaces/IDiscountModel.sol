// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IDiscountModel {
    /**
     * @notice Computes the discount factor for a given principal token.
     * @dev This function can be implemented customly, so not all argumnets need to be used
     *
     * @param initialImpliedAPY The initial implied APY of the principal token (in 18 decimals).
     * @param timeLeft The time remaining until maturity, in seconds.
     * @param futurePTValue The future value of the principal token at maturity.
     * @return discount The computed discount factor, expressed with futurePTValue's decimals precision.
     */
    function getDiscount(
        uint256 initialImpliedAPY,
        uint256 timeLeft,
        uint256 futurePTValue
    ) external pure returns (uint256 discount);

    /**
     * @notice Returns a human-readable description of the discount model.
     * @return A string describing the discount model.
     */
    function description() external pure returns (string memory);
}