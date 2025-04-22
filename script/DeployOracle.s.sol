// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ISpectraPriceOracleFactory} from "../test/interfaces/ISpectraPriceOracleFactory.sol";

contract DeployOracleScript is Script {
    function setUp() public {}

    function run() public {
        // Load environment variables
        address factory = vm.envAddress("ORACLE_FACTORY_ADDRESS");
        address pt = vm.envAddress("PT_ADDRESS");
        address discountModel = vm.envAddress("LINEAR_MODEL_ADDRESS");
        uint256 initialAPY = vm.envUint("INITIAL_IMPLIED_APY");
        address owner = vm.envAddress("ORACLE_OWNER");

        // Validate addresses
        require(factory != address(0), "ORACLE_FACTORY_ADDRESS cannot be zero address");
        require(pt != address(0), "PT_ADDRESS cannot be zero address");
        require(discountModel != address(0), "LINEAR_MODEL_ADDRESS cannot be zero address");
        require(owner != address(0), "ORACLE_OWNER cannot be zero address");

        // Validate initialAPY (between 0 and 50%)
        require(initialAPY > 0, "INITIAL_IMPLIED_APY must be greater than 0");
        require(initialAPY < 5e17, "INITIAL_IMPLIED_APY must be less than 50%");

        vm.startBroadcast();

        // Deploy oracle
        address oracle = ISpectraPriceOracleFactory(factory).createOracle(
            pt,
            discountModel,
            initialAPY,
            owner
        );

        console.log("Oracle deployed at:", oracle);

        vm.stopBroadcast();
    }
}
