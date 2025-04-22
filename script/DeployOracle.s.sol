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
