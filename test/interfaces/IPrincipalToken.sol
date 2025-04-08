// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IPrincipalToken is IERC4626 {
    function getIBT() external view returns (address);
    function maturity() external view returns (uint256);
}