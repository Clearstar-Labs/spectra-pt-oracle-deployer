// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

interface ICurvePool {
    function coins(uint256 i) external view returns (address);
    function balances(uint256 i) external view returns (uint256);
}

contract LiquidityChecker is Test {
    function checkPoolLiquidity(address curvePool) public view {
        ICurvePool pool = ICurvePool(curvePool);

        console.log("-------------------------------------------------------------------------------------");
        console.log("Curve pool liquidity - Make sure there is enough liquidity for accurate pricing!");
        
        for (uint256 i = 0; i < 2; i++) {
            address token = pool.coins(i);
            uint256 balance = pool.balances(i);
            IERC20Metadata tokenMeta = IERC20Metadata(token);
            uint256 decimals = tokenMeta.decimals();
            string memory symbol = tokenMeta.symbol();
            string memory name = tokenMeta.name();
            
            // Convert to 2 decimal places
            uint256 balanceScaled = (balance * 100) / (10 ** decimals);
            uint256 whole = balanceScaled / 100;
            uint256 fraction = balanceScaled % 100;
            
            console.log("Token", i);
            console.log("Address:", token);
            console.log("Name:", name);
            console.log("Symbol:", symbol);
            console.log("Raw Balance:", balance);
            console.log(
                string.concat(
                    "Balance in Units: ",
                    vm.toString(whole),
                    ".",
                    fraction < 10 ? "0" : "",
                    vm.toString(fraction)
                )
            );
            console.log("-------------------------------------------------------------------------------------");
        }
    }
}
