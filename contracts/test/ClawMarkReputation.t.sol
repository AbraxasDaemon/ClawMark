// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ClawMarkReputation.sol";

contract ClawMarkReputationTest is Test {
    ClawMarkReputation public reputation;
    
    address owner = address(this);
    address oracle = address(0x1);
    address randomUser = address(0x2);
    
    bytes32 testDidHash = keccak256("did:agent:moltbook:testuser");
    
    function setUp() public {
        reputation = new ClawMarkReputation();
        reputation.setAuthorizedOracle(oracle, true);
    }
    
    function test_UpdateScore() public {
        vm.prank(oracle);
        reputation.updateScore(
            testDidHash,
            500,  // score
            80,   // reliability
            75,   // taskCompletion
            90,   // security
            85,   // timeliness
            10    // peerEndorsements
        );
        
        ClawMarkReputation.ReputationScore memory score = reputation.getScore(testDidHash);
        
        assertEq(score.didHash, testDidHash);
        assertEq(score.score, 500);
        assertEq(score.maxScore, 1000);
        assertEq(keccak256(bytes(score.tier)), keccak256(bytes("silver")));
        assertGt(score.updatedAt, 0);
        assertEq(score.updatedBy, oracle);
        assertEq(score.version, 1);
    }
    
    function test_RevertWhenNotOracle() public {
        vm.prank(randomUser);
        vm.expectRevert("Not authorized oracle");
        reputation.updateScore(testDidHash, 500, 80, 75, 90, 85, 10);
    }
    
    function test_RevertWhenScoreTooHigh() public {
        vm.prank(oracle);
        vm.expectRevert("Score exceeds max");
        reputation.updateScore(testDidHash, 1500, 80, 75, 90, 85, 10);
    }
    
    function test_UpdateScoreIncrementsVersion() public {
        vm.startPrank(oracle);
        
        reputation.updateScore(testDidHash, 300, 70, 70, 70, 70, 5);
        ClawMarkReputation.ReputationScore memory s1 = reputation.getScore(testDidHash);
        assertEq(s1.version, 1);
        
        reputation.updateScore(testDidHash, 500, 80, 75, 85, 80, 10);
        ClawMarkReputation.ReputationScore memory s2 = reputation.getScore(testDidHash);
        assertEq(s2.version, 2);
        
        reputation.updateScore(testDidHash, 700, 90, 85, 90, 90, 15);
        ClawMarkReputation.ReputationScore memory s3 = reputation.getScore(testDidHash);
        assertEq(s3.version, 3);
        
        vm.stopPrank();
    }
    
    function test_SetAuthorizedOracle() public {
        address newOracle = address(0x3);
        
        assertFalse(reputation.authorizedOracles(newOracle));
        
        reputation.setAuthorizedOracle(newOracle, true);
        assertTrue(reputation.authorizedOracles(newOracle));
        
        reputation.setAuthorizedOracle(newOracle, false);
        assertFalse(reputation.authorizedOracles(newOracle));
    }
    
    function test_OwnerCanUpdateScore() public {
        // Owner should also be able to update scores
        reputation.updateScore(testDidHash, 800, 95, 90, 95, 95, 20);
        
        ClawMarkReputation.ReputationScore memory score = reputation.getScore(testDidHash);
        assertEq(score.score, 800);
    }
    
    function test_GetScoreForUnregistered() public {
        bytes32 unregisteredDid = keccak256("unregistered");
        
        ClawMarkReputation.ReputationScore memory score = reputation.getScore(unregisteredDid);
        
        assertEq(score.score, 0);
        assertEq(score.maxScore, 1000);
        assertEq(score.updatedAt, 0);
    }
    
    function test_TierProgression() public {
        vm.startPrank(oracle);
        
        // Bronze (0-399)
        reputation.updateScore(testDidHash, 200, 50, 50, 50, 50, 2);
        ClawMarkReputation.ReputationScore memory s1 = reputation.getScore(testDidHash);
        assertEq(keccak256(bytes(s1.tier)), keccak256(bytes("bronze")));
        
        // Silver (400-599)
        reputation.updateScore(testDidHash, 450, 70, 70, 70, 70, 5);
        ClawMarkReputation.ReputationScore memory s2 = reputation.getScore(testDidHash);
        assertEq(keccak256(bytes(s2.tier)), keccak256(bytes("silver")));
        
        // Gold (600-799)
        reputation.updateScore(testDidHash, 700, 85, 85, 85, 85, 10);
        ClawMarkReputation.ReputationScore memory s3 = reputation.getScore(testDidHash);
        assertEq(keccak256(bytes(s3.tier)), keccak256(bytes("gold")));
        
        // Platinum (800-1000)
        reputation.updateScore(testDidHash, 900, 95, 95, 95, 95, 20);
        ClawMarkReputation.ReputationScore memory s4 = reputation.getScore(testDidHash);
        assertEq(keccak256(bytes(s4.tier)), keccak256(bytes("platinum")));
        
        vm.stopPrank();
    }
    
    function test_MetricsStored() public {
        vm.prank(oracle);
        reputation.updateScore(testDidHash, 650, 85, 80, 90, 88, 12);
        
        (
            uint256 reliability,
            uint256 taskCompletion,
            uint256 security,
            uint256 timeliness,
            uint256 peerEndorsements,
            ,
        ) = reputation.metrics(testDidHash);
        
        assertEq(reliability, 85);
        assertEq(taskCompletion, 80);
        assertEq(security, 90);
        assertEq(timeliness, 88);
        assertEq(peerEndorsements, 12);
    }
}
