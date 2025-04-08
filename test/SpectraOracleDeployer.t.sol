// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface ISpectraPriceOracle {
    function PT() external view returns (address);
    function discountModel() external view returns (address);
    function initialImpliedAPY() external view returns (uint256);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

interface ISpectraPriceOracleFactory {
    function createOracle(
        address _pt,
        address _discountModel,
        uint256 initialImpliedAPY,
        address initOwner
    ) external returns (address);
}

interface IPrincipalToken is IERC4626 {
    function getIBT() external view returns (address);
    function maturity() external view returns (uint256);
}

contract SpectraOracleDeployerTest is Test {
    IPrincipalToken public principalToken;
    ISpectraPriceOracleFactory public factory;
    uint256 public fork;
    address constant FACTORY_ADDRESS = 0xAA055F599f698E5334078F4921600Bd16CceD561;
    address constant ZCB_MODEL = 0xf0DB3482c20Fc6E124D5B5C60BdF30BD13EC87aE;

    function setUp() public {
        // Create and select a fork of Base
        fork = vm.createFork(vm.envString("BASE_RPC_URL"));
        vm.selectFork(fork);
        
        // Initialize PT contract interface
        principalToken = IPrincipalToken(0x95590E979A72B6b04D829806E8F29aa909eD3a86);
        factory = ISpectraPriceOracleFactory(FACTORY_ADDRESS);
    }

    function test_DeployOracle() public {
        // Initial APY of 5%
        uint256 initialAPY = 0.05e18;
        
        // Deploy oracle
        address oracle = factory.createOracle(
            address(principalToken),
            ZCB_MODEL,
            initialAPY,
            address(this) // Set test contract as owner
        );
        
        console.log("Oracle deployed at:", oracle);
        
        // Verify oracle was created correctly
        ISpectraPriceOracle deployedOracle = ISpectraPriceOracle(oracle);
        
        // Check oracle parameters
        assertEq(deployedOracle.PT(), address(principalToken), "Wrong PT address");
        assertEq(deployedOracle.discountModel(), ZCB_MODEL, "Wrong discount model");
        assertEq(deployedOracle.initialImpliedAPY(), initialAPY, "Wrong initial APY");
        
        // Get first price reading
        (,int256 price,,,) = deployedOracle.latestRoundData();
        console.log("Initial oracle price:", uint256(price));
        assertTrue(price > 0, "Price should be greater than 0");
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
