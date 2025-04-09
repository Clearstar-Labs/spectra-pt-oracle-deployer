// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import {IPrincipalToken} from "../interfaces/IPrincipalToken.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract APYCalculator {
    uint256 private constant UNIT = 1e18;
    uint256 private constant SECONDS_PER_YEAR = 365 days;

    function calculateInitialImpliedAPY(
        address pt,
        uint256 curveInitialPrice
    ) external view returns (uint256) {
        IPrincipalToken principalToken = IPrincipalToken(pt);
        address ibt = principalToken.getIBT();
        
        // Get current IBT yield
        uint256 ibtRate = IERC4626(ibt).convertToAssets(UNIT);
        // Calculate deployment timestamp using maturity - duration
        uint256 deploymentTimestamp = principalToken.maturity() - principalToken.getDuration();
        uint256 ibtYield = ((ibtRate - UNIT) * SECONDS_PER_YEAR) / (block.timestamp - deploymentTimestamp);
        
        // Calculate time to maturity
        uint256 timeToMaturity = principalToken.maturity() - block.timestamp;
        
        // Calculate implied APY from Curve initial price
        uint256 impliedAPY = (SECONDS_PER_YEAR * (UNIT - curveInitialPrice)) / (timeToMaturity * curveInitialPrice);
        
        // Use the higher of IBT yield and implied Curve APY
        return ibtYield > impliedAPY ? ibtYield : impliedAPY;
    }
}
