// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IPrincipalToken} from "./interfaces/IPrincipalToken.sol";
import {ISpectraPriceOracleFactory} from "./interfaces/ISpectraPriceOracleFactory.sol";
import {ISpectraPriceOracle} from "./interfaces/ISpectraPriceOracle.sol";
import {APYCalculator} from "./utils/APYCalculator.sol";

contract SpectraOracleDeployerTest is Test {
    IPrincipalToken public principalToken;
    address public curvePool;
    ISpectraPriceOracleFactory public oracle_factory;
    APYCalculator public calculator;
    uint256 public fork;
    
    address public zcbModel;
    string public RPC_URL;

    function setUp() public {
        // Load environment variables
        RPC_URL = vm.envString("RPC_URL");
        address pt = vm.envAddress("PT_ADDRESS");
        address pool = vm.envAddress("POOL_ADDRESS");
        address factory = vm.envAddress("ORACLE_FACTORY_ADDRESS");
        zcbModel = vm.envAddress("ZCB_MODEL_ADDRESS");
        
        // Create and select fork
        fork = vm.createFork(RPC_URL);
        vm.selectFork(fork);
        
        // Initialize contracts
        principalToken = IPrincipalToken(pt);
        curvePool = pool;
        oracle_factory = ISpectraPriceOracleFactory(factory);
        calculator = new APYCalculator();
    }

    function test_DeployOracle() public {
        uint256 initialAPY = calculator.calculateImpliedAPY(
            principalToken,
            curvePool
        );
        
        // Deploy oracle
        address oracle = oracle_factory.createOracle(
            address(principalToken),
            zcbModel,
            initialAPY,
            address(this)
        );
        
        console.log("Oracle deployed at:", oracle);
        
        // Verify oracle was created correctly
        ISpectraPriceOracle deployedOracle = ISpectraPriceOracle(oracle);
        
        // Check oracle parameters
        assertEq(deployedOracle.PT(), address(principalToken), "Wrong PT address");
        assertEq(deployedOracle.discountModel(), zcbModel, "Wrong discount model");
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
        
        // Get and log the underlying token address through IBT
        address underlying = IERC4626(ibt).asset();
        console.log("Underlying token address:", underlying);
        
        // Get and log maturity timestamp
        uint256 maturityTimestamp = principalToken.maturity();
        console.log("PT maturity timestamp:", maturityTimestamp);
        
        // Get and log PT symbol
        string memory symbol = principalToken.symbol();
        console.log("PT symbol:", symbol);

        // Verify this is a real PT by checking it has an IBT
        assertTrue(ibt != address(0), "Should have valid IBT address");
        // Verify this is a real IBT by checking it has an underlying
        assertTrue(underlying != address(0), "Should have valid underlying address");
        // Verify maturity is in the future
        assertTrue(maturityTimestamp > block.timestamp, "Should have future maturity");
    }

    function test_calculateIBTYield() public {
        // Get the IBT address
        address ibt = principalToken.getIBT();
        console.log("IBT address:", ibt);
        
        // Calculate and log IBT yield
        calculator.calculateIBTYield(ibt);
    }
}
