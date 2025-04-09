// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IPrincipalToken} from "./interfaces/IPrincipalToken.sol";
import {ISpectraPriceOracleFactory} from "./interfaces/ISpectraPriceOracleFactory.sol";
import {ISpectraFactory} from "./interfaces/ISpectraFactory.sol";
import {ISpectraPriceOracle} from "./interfaces/ISpectraPriceOracle.sol";
import {IRegistry} from "./interfaces/IRegistry.sol";
import {ICurveAddressProvider} from "./interfaces/ICurveAddressProvider.sol";
import {APYCalculator} from "./utils/APYCalculator.sol";

contract SpectraOracleDeployerTest is Test {
    IPrincipalToken public principalToken;
    address public curvePool;
    ISpectraPriceOracleFactory public oracle_factory;
    ISpectraFactory public spectra_factory;
    APYCalculator public calculator;
    uint256 public fork;
    address constant FACTORY_ADDRESS = 0xAA055F599f698E5334078F4921600Bd16CceD561;
    address constant SPECTRA_FACTORY_ADDRESS = 0x51100574E1CF11ee9fcC96D70ED146250b0Fdb60; // Add the actual address
    address constant REGISTRY_ADDRESS = 0x786Da12e9836a9ff9b7d92e8bac1C849e2ACe378;
    address constant ZCB_MODEL = 0xf0DB3482c20Fc6E124D5B5C60BdF30BD13EC87aE;

    address constant PT_FUSDC = 0x95590E979A72B6b04D829806E8F29aa909eD3a86;
    address constant LP_FUSDC = 0xee901F017B5D7C583619604d807e3590162bFb35;
    address constant POOL_FUSDC = 0x39E6Af30ea89034D1BdD2d1CfbA88cAF8464Fa65;

    address constant PT_CUSDO = 0x1155d1731B495BF22f016e13cAfb6aFA53BD8a28;
    address constant LP_CUSDO = 0x865f8b843e942aacA4D058A8708B57651C0af356;
    address constant POOL_CUSDO = 0x5e3A444CbBaBF92d619fA9FCAEef99c24Ead3Ba0;

    function setUp() public {
        // Create and select a fork of Base
        fork = vm.createFork(vm.envString("BASE_RPC_URL"));
        vm.selectFork(fork);
        
        // Initialize contracts
        principalToken = IPrincipalToken(PT_FUSDC);
        curvePool = POOL_FUSDC;
        oracle_factory = ISpectraPriceOracleFactory(FACTORY_ADDRESS);
        spectra_factory = ISpectraFactory(SPECTRA_FACTORY_ADDRESS);
        calculator = new APYCalculator();
    }

    function test_DeployOracle() public {
        // uint256 initialAPY = calculateImpliedAPY();
        // Initial APY of 5%
        uint256 initialAPY = 0.051e18;
        
        // Deploy oracle
        address oracle = oracle_factory.createOracle(
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

    function test_ChainID() public view {
        assertEq(block.chainid, 8453); // Base mainnet chain ID
    }

    function test_CalculateInitialImpliedAPY() public {
        uint256 impliedAPY = calculateImpliedAPY();
        console.log("Calculated initial implied APY:", impliedAPY);
        
        // Basic sanity checks
        assertTrue(impliedAPY > 0, "APY should be greater than 0");
        assertTrue(impliedAPY < 1e18, "APY should be less than 100%");
    }

    function calculateImpliedAPY() private returns (uint256) {
        // Get initial price from Curve pool
        (bool success, bytes memory data) = curvePool.call(
            abi.encodeWithSignature("price_scale()")
        );
        require(success, "Failed to get price_scale");
        uint256 curveInitialPrice = abi.decode(data, (uint256));
        console.log("curveInitialPrice:", curveInitialPrice);

        // uint256 curveInitialPrice = 934000000000000000;
        
        uint256 impliedAPY = calculator.calculateInitialImpliedAPY(
            address(principalToken),
            curveInitialPrice
        );
        
        console.log("Curve initial price:", curveInitialPrice);
        return impliedAPY;
    }

    // function test_GetAllPTsAndCurvePools() public {
    //     // Get Registry and Curve Address Provider addresses
    //     address registryAddress = spectra_factory.getRegistry();
    //     //address curveAddressProvider = spectra_factory.getCurveAddressProvider();
        
    //     console.log("Registry address:", registryAddress);
    //     //console.log("Curve Address Provider:", curveAddressProvider);
        
    //     // // Create interface instances
    //     // IRegistry registry = IRegistry(registryAddress);
    //     // ICurveAddressProvider provider = ICurveAddressProvider(curveAddressProvider);
        
    //     // // Get total number of PTs
    //     // uint256 totalPTs = registry.pTCount();
    //     // console.log("Total number of PTs:", totalPTs);
        
    //     // // Loop through all PTs
    //     // for (uint256 i = 0; i < totalPTs; i++) {
    //     //     address pt = registry.getPTAt(i);
    //     //     // According to Curve documentation, curve factory address is at index 6
    //     //     address curveAddress = provider.get_address(6);
            
    //     //     console.log("PT Index:", i);
    //     //     console.log("PT Address:", pt);
    //     //     console.log("Curve Factory Address:", curveAddress);
    //     //     console.log("-------------------");
    //     // }
    // }
}
