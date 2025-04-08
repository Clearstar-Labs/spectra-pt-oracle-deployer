// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IPrincipalToken is IERC4626 {
    function getIBT() external view returns (address);
    function maturity() external view returns (uint256);
}

contract CounterTest is Test {
    IPrincipalToken public principalToken;
    uint256 public fork;

    function setUp() public {
        // Create and select a fork of Base
        fork = vm.createFork(vm.envString("BASE_RPC_URL"));
        vm.selectFork(fork);
        
        // Initialize PT contract interface
        principalToken = IPrincipalToken(0x95590E979A72B6b04D829806E8F29aa909eD3a86);
    }

    function test_VerifyPT() public view {
        // Get and log the IBT address
        address ibt = principalToken.getIBT();
        console.log("IBT address:", ibt);
        
        // Get and log maturity timestamp
        uint256 maturityTimestamp = principalToken.maturity();
        console.log("PT maturity timestamp:", maturityTimestamp);
        
        // Get and log PT symbol
        string memory symbol = principalToken.symbol();
        console.log("PT symbol:", symbol);

        // Verify this is a real PT by checking it has an IBT
        assertTrue(ibt != address(0), "Should have valid IBT address");
        // Verify maturity is in the future
        assertTrue(maturityTimestamp > block.timestamp, "Should have future maturity");
    }

    function test_ChainID() public view {
        assertEq(block.chainid, 8453); // Base mainnet chain ID
    }
}
