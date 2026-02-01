// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ClawMarkCredentials.sol";

contract ClawMarkCredentialsTest is Test {
    ClawMarkCredentials public credentials;
    
    address owner = address(this);
    address issuer = address(0x1);
    address randomUser = address(0x2);
    
    bytes32 testDidHash = keccak256("did:agent:moltbook:testuser");
    bytes32 testCredHash = keccak256("test-credential-hash");
    
    function setUp() public {
        credentials = new ClawMarkCredentials();
        credentials.setTrustedIssuer(issuer, true);
    }
    
    function test_AnchorCredential() public {
        vm.prank(issuer);
        credentials.anchorCredential(
            testCredHash,
            testDidHash,
            "PlatformVerification",
            0 // no expiration
        );
        
        (
            bytes32 credentialHash,
            bytes32 didHash,
            string memory credentialType,
            uint256 issuedAt,
            uint256 expiresAt,
            bool revoked
        ) = credentials.anchors(testCredHash);
        
        assertEq(credentialHash, testCredHash);
        assertEq(didHash, testDidHash);
        assertEq(credentialType, "PlatformVerification");
        assertGt(issuedAt, 0);
        assertEq(expiresAt, 0);
        assertFalse(revoked);
    }
    
    function test_RevertWhenNotTrustedIssuer() public {
        vm.prank(randomUser);
        vm.expectRevert("Not trusted issuer");
        credentials.anchorCredential(
            testCredHash,
            testDidHash,
            "PlatformVerification",
            0
        );
    }
    
    function test_RevertWhenDuplicateCredential() public {
        vm.prank(issuer);
        credentials.anchorCredential(
            testCredHash,
            testDidHash,
            "PlatformVerification",
            0
        );
        
        vm.prank(issuer);
        vm.expectRevert("Credential already anchored");
        credentials.anchorCredential(
            testCredHash,
            testDidHash,
            "PlatformVerification",
            0
        );
    }
    
    function test_RevokeCredential() public {
        vm.prank(issuer);
        credentials.anchorCredential(
            testCredHash,
            testDidHash,
            "PlatformVerification",
            0
        );
        
        vm.prank(issuer);
        credentials.revokeCredential(testCredHash);
        
        (,,,,, bool revoked) = credentials.anchors(testCredHash);
        assertTrue(revoked);
    }
    
    function test_VerifyCredential() public {
        vm.prank(issuer);
        credentials.anchorCredential(
            testCredHash,
            testDidHash,
            "PlatformVerification",
            0
        );
        
        (bool valid, string memory reason) = credentials.verifyCredential(testCredHash);
        assertTrue(valid);
        assertEq(reason, "Valid");
    }
    
    function test_VerifyRevokedCredential() public {
        vm.prank(issuer);
        credentials.anchorCredential(
            testCredHash,
            testDidHash,
            "PlatformVerification",
            0
        );
        
        vm.prank(issuer);
        credentials.revokeCredential(testCredHash);
        
        (bool valid, string memory reason) = credentials.verifyCredential(testCredHash);
        assertFalse(valid);
        assertEq(reason, "Revoked");
    }
    
    function test_VerifyExpiredCredential() public {
        vm.prank(issuer);
        credentials.anchorCredential(
            testCredHash,
            testDidHash,
            "PlatformVerification",
            block.timestamp + 1 // expires in 1 second
        );
        
        // Fast forward past expiration
        vm.warp(block.timestamp + 2);
        
        (bool valid, string memory reason) = credentials.verifyCredential(testCredHash);
        assertFalse(valid);
        assertEq(reason, "Expired");
    }
    
    function test_SetTrustedIssuer() public {
        address newIssuer = address(0x3);
        
        assertFalse(credentials.trustedIssuers(newIssuer));
        
        credentials.setTrustedIssuer(newIssuer, true);
        assertTrue(credentials.trustedIssuers(newIssuer));
        
        credentials.setTrustedIssuer(newIssuer, false);
        assertFalse(credentials.trustedIssuers(newIssuer));
    }
    
    function test_GetAgentCredentials() public {
        bytes32 cred1 = keccak256("cred1");
        bytes32 cred2 = keccak256("cred2");
        
        vm.startPrank(issuer);
        credentials.anchorCredential(cred1, testDidHash, "Type1", 0);
        credentials.anchorCredential(cred2, testDidHash, "Type2", 0);
        vm.stopPrank();
        
        bytes32[] memory agentCreds = credentials.getAgentCredentials(testDidHash);
        assertEq(agentCreds.length, 2);
        assertEq(agentCreds[0], cred1);
        assertEq(agentCreds[1], cred2);
    }
}
