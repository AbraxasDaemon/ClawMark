// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ClawMarkRegistry.sol";

/**
 * @title ClawMarkRegistryTest
 * @notice Test suite for ClawMarkRegistry
 */
contract ClawMarkRegistryTest is Test {
    ClawMarkRegistry public registry;
    
    address public owner = address(1);
    address public controller = address(2);
    address public attacker = address(3);
    
    bytes32 public testDidHash = keccak256("did:agent:base:test123");
    bytes public testPublicKey = hex"abcdef123456";
    
    uint256 public constant MINIMUM_STAKE = 0.001 ether;
    
    function setUp() public {
        vm.prank(owner);
        registry = new ClawMarkRegistry(MINIMUM_STAKE);
    }
    
    // ============ Registration Tests ============
    
    function test_Register() public {
        vm.deal(controller, 1 ether);
        
        vm.prank(controller);
        bytes32 didHash = registry.register{value: MINIMUM_STAKE}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
        
        assertEq(didHash, testDidHash);
        
        ClawMarkRegistry.AgentRecord memory agent = registry.resolve(testDidHash);
        assertEq(agent.didHash, testDidHash);
        assertEq(agent.controller, controller);
        assertEq(agent.platform, "moltbook");
        assertTrue(agent.active);
        assertEq(agent.stake, MINIMUM_STAKE);
    }
    
    function test_RevertRegister_InsufficientStake() public {
        vm.deal(controller, 1 ether);
        
        vm.prank(controller);
        vm.expectRevert("Insufficient stake");
        registry.register{value: 0.0001 ether}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
    }
    
    function test_RevertRegister_DuplicateDID() public {
        vm.deal(controller, 1 ether);
        
        vm.prank(controller);
        registry.register{value: MINIMUM_STAKE}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
        
        vm.prank(controller);
        vm.expectRevert("DID already exists");
        registry.register{value: MINIMUM_STAKE}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
    }
    
    // ============ Key Rotation Tests ============
    
    function test_RotateKey() public {
        vm.deal(controller, 1 ether);
        
        vm.prank(controller);
        registry.register{value: MINIMUM_STAKE}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
        
        bytes memory newKey = hex"9876543210fedcba";
        
        vm.prank(controller);
        registry.rotateKey(testDidHash, newKey);
        
        ClawMarkRegistry.AgentRecord memory agent = registry.resolve(testDidHash);
        assertEq(keccak256(agent.publicKey), keccak256(newKey));
    }
    
    function test_RevertRotateKey_NotController() public {
        vm.deal(controller, 1 ether);
        
        vm.prank(controller);
        registry.register{value: MINIMUM_STAKE}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
        
        bytes memory newKey = hex"9876543210fedcba";
        
        vm.prank(attacker);
        vm.expectRevert("Not controller");
        registry.rotateKey(testDidHash, newKey);
    }
    
    // ============ Deactivation Tests ============
    
    function test_DeactivateAndReactivate() public {
        vm.deal(controller, 1 ether);
        
        vm.prank(controller);
        registry.register{value: MINIMUM_STAKE}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
        
        vm.prank(controller);
        registry.deactivate(testDidHash, "Testing deactivation");
        
        assertFalse(registry.isActive(testDidHash));
        
        vm.prank(controller);
        registry.reactivate(testDidHash);
        
        assertTrue(registry.isActive(testDidHash));
    }
    
    // ============ Stake Tests ============
    
    function test_IncreaseStake() public {
        vm.deal(controller, 1 ether);
        
        vm.prank(controller);
        registry.register{value: MINIMUM_STAKE}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
        
        vm.prank(controller);
        registry.increaseStake{value: 0.001 ether}(testDidHash);
        
        ClawMarkRegistry.AgentRecord memory agent = registry.resolve(testDidHash);
        assertEq(agent.stake, MINIMUM_STAKE + 0.001 ether);
    }
    
    function test_WithdrawStake() public {
        vm.deal(controller, 1 ether);
        
        vm.prank(controller);
        registry.register{value: MINIMUM_STAKE * 2}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
        
        uint256 withdrawAmount = MINIMUM_STAKE;
        uint256 balanceBefore = controller.balance;
        
        vm.prank(controller);
        registry.withdrawStake(testDidHash, withdrawAmount);
        
        uint256 balanceAfter = controller.balance;
        assertEq(balanceAfter - balanceBefore, withdrawAmount);
        
        ClawMarkRegistry.AgentRecord memory agent = registry.resolve(testDidHash);
        assertEq(agent.stake, MINIMUM_STAKE);
    }
    
    // ============ Owner Tests ============
    
    function test_Slash() public {
        vm.deal(controller, 1 ether);
        
        vm.prank(controller);
        registry.register{value: MINIMUM_STAKE}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
        
        uint256 slashAmount = 0.0005 ether;
        
        vm.prank(owner);
        registry.slash(testDidHash, slashAmount, "Malicious behavior");
        
        ClawMarkRegistry.AgentRecord memory agent = registry.resolve(testDidHash);
        assertEq(agent.stake, MINIMUM_STAKE - slashAmount);
    }
    
    function test_RevertSlash_NotOwner() public {
        vm.deal(controller, 1 ether);
        
        vm.prank(controller);
        registry.register{value: MINIMUM_STAKE}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
        
        vm.prank(attacker);
        vm.expectRevert("Ownable: caller is not the owner");
        registry.slash(testDidHash, 0.0005 ether, "Malicious behavior");
    }
    
    function test_Revoke() public {
        vm.deal(controller, 1 ether);
        
        vm.prank(controller);
        registry.register{value: MINIMUM_STAKE}(
            testDidHash,
            testPublicKey,
            "moltbook"
        );
        
        vm.prank(owner);
        registry.revoke(testDidHash, "Severe violation");
        
        assertTrue(registry.isRevoked(testDidHash));
    }
}
