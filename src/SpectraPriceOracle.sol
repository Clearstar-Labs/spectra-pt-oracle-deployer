// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {IDiscountModel} from "./interfaces/IDiscountModel.sol";
import {IPrincipalToken} from "./interfaces/IPrincipalToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SpectraPriceOracle is Ownable {
    uint256 private constant SECONDS_PER_YEAR = 365 days;
    uint256 private immutable UNIT;
    address public immutable PT;
    uint256 public immutable maturity;
    address public discountModel; // External discount model
    uint256 public initialImpliedAPY;
    uint8 private underlyingDecimals;

    event DiscountModelUpdated(address newModel);

    constructor(address _pt, address _discountModel, uint256 _initialImpliedAPY, address initOwner) Ownable(initOwner) {
        require(_pt != address(0), "zero address");
        PT = _pt;
        address underlying = IPrincipalToken(PT).underlying();
        underlyingDecimals = IERC20Metadata(underlying).decimals();
        maturity = IPrincipalToken(PT).maturity();
        discountModel = _discountModel;
        initialImpliedAPY = _initialImpliedAPY;
        UNIT = 10 ** IPrincipalToken(PT).decimals();

        uint256 timeLeft = ptTimeLeft();
        uint256 futurePTValue = IPrincipalToken(PT).convertToUnderlying(UNIT);
        require(getDiscount(timeLeft, futurePTValue) <= futurePTValue, "discount overflow");
    }

    function ptTimeLeft() public view returns (uint256) {
        return (maturity > block.timestamp) ? maturity - block.timestamp : 0;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint256 timeLeft = ptTimeLeft();

        uint256 futurePTValue = IPrincipalToken(PT).convertToUnderlying(UNIT);
        //Get the discount with the time left
        uint256 discount = getDiscount(timeLeft, futurePTValue);

        require(discount <= futurePTValue, "discount overflow");
        return (0, int256(futurePTValue - discount), 0, 0, 0);
    }

    function getDiscount(uint256 timeLeft, uint256 futurePTValue) public view returns (uint256) {
        return IDiscountModel(discountModel).getDiscount(initialImpliedAPY, timeLeft, futurePTValue);
    }

    /// @notice Update the discount model
    function setDiscountModel(address _newModel) external onlyOwner {
        require(_newModel != address(0), "zero discount model");
        discountModel = _newModel;
        emit DiscountModelUpdated(_newModel);
    }

    /// @notice Get the decimals of the asset
    function decimals() external view returns (uint8) {
        return underlyingDecimals;
    }
}