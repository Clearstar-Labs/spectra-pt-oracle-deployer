// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import {IDiscountModel} from "./interfaces/IDiscountModel.sol";
import {IPrincipalToken} from "./interfaces/IPrincipalToken.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SpectraPriceOracle is OwnableUpgradeable {
    uint256 private constant SECONDS_PER_YEAR = 365 days;
    uint256 private UNIT;
    address public PT;
    uint256 public maturity;
    address public discountModel; // External discount model
    uint256 public initialImpliedAPY;
    uint8 private underlyingDecimals;
    uint256 private underlyingUnit;

    uint256[50] private __gap;

    event DiscountModelUpdated(address newModel);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _pt,
        address _discountModel,
        uint256 _initialImpliedAPY,
        address initOwner
    ) external initializer {
        __Ownable_init(initOwner);
        require(_pt != address(0), "zero address");
        PT = _pt;
        address underlying = IPrincipalToken(PT).underlying();
        underlyingDecimals = IERC20Metadata(underlying).decimals();
        underlyingUnit = 10 ** underlyingDecimals;
        maturity = IPrincipalToken(PT).maturity();
        discountModel = _discountModel;
        initialImpliedAPY = _initialImpliedAPY;
        UNIT = 10 ** IPrincipalToken(PT).decimals();
        uint256 timeLeft = ptTimeLeft();
        uint256 futurePTValue = IPrincipalToken(PT).convertToUnderlying(UNIT);
        require(getPrice(timeLeft, futurePTValue) > 0, "price must be greater than 0");
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
        uint256 price = getPrice(timeLeft, futurePTValue);

        return (0, int256(price), 0, 0, 0);
    }

    function getPrice(uint256 timeLeft, uint256 futurePTValue) public view returns (uint256) {
        return IDiscountModel(discountModel).getPrice(initialImpliedAPY, timeLeft, futurePTValue, underlyingUnit);
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
