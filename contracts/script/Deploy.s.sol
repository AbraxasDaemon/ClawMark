// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/ClawMarkRegistry.sol";
import "../src/ClawMarkCredentials.sol";
import "../src/ClawMarkReputation.sol";

/**
 * @title Deploy
 * @notice Deployment script for AgentVerify contracts
 * @dev Run: forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast
 */
contract Deploy is Script {
    
    uint256 public constant MINIMUM_STAKE = 0.001 ether; // ~$2 at current prices
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying AgentVerify contracts...");
        console.log("Deployer:", deployer);
        
        // Deploy Registry
        ClawMarkRegistry registry = new ClawMarkRegistry(MINIMUM_STAKE);
        console.log("ClawMarkRegistry deployed at:", address(registry));
        
        // Deploy Credentials
        ClawMarkCredentials credentials = new ClawMarkCredentials();
        console.log("ClawMarkCredentials deployed at:", address(credentials));
        
        // Deploy Reputation
        ClawMarkReputation reputation = new ClawMarkReputation();
        console.log("ClawMarkReputation deployed at:", address(reputation));
        
        // Set deployer as trusted issuer and oracle
        credentials.setTrustedIssuer(deployer, true);
        reputation.setAuthorizedOracle(deployer, true);
        
        console.log("Deployer authorized as issuer and oracle");
        console.log("Deployment complete!");
        
        // Log addresses for verification
        console.log("\n=== Contract Addresses ===");
        console.log("Registry:   ", address(registry));
        console.log("Credentials:", address(credentials));
        console.log("Reputation: ", address(reputation));
        
        vm.stopBroadcast();
    }
}
