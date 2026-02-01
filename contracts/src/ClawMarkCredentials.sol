// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ClawMarkCredentials
 * @notice On-chain credential anchoring (hashes only, not full VCs)
 * @dev Stores credential hashes for tamper-proof verification
 */
contract ClawMarkCredentials is Ownable {
    
    constructor() Ownable(msg.sender) {}
    
    // ============ Structs ============
    
    struct CredentialAnchor {
        bytes32 credentialHash;
        bytes32 didHash;
        string credentialType;
        uint256 issuedAt;
        uint256 expiresAt;
        bool revoked;
    }
    
    // ============ State ============
    
    // credentialHash => anchor
    mapping(bytes32 => CredentialAnchor) public anchors;
    
    // didHash => array of credential hashes
    mapping(bytes32 => bytes32[]) public agentCredentials;
    
    // issuer => isTrusted
    mapping(address => bool) public trustedIssuers;
    
    uint256 public totalAnchors;
    
    // ============ Events ============
    
    event CredentialAnchored(
        bytes32 indexed credentialHash,
        bytes32 indexed didHash,
        address indexed issuer,
        string credentialType
    );
    
    event CredentialRevoked(
        bytes32 indexed credentialHash,
        address indexed revokedBy,
        uint256 revokedAt
    );
    
    event IssuerTrusted(
        address indexed issuer,
        bool trusted
    );
    
    // ============ Modifiers ============
    
    modifier onlyTrustedIssuer() {
        require(trustedIssuers[msg.sender] || msg.sender == owner(), "Not trusted issuer");
        _;
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Anchor a credential hash on-chain
     * @param _credentialHash Hash of the full credential
     * @param _didHash Hash of the subject DID
     * @param _credentialType Type of credential (identity, capability, reputation)
     * @param _expiresAt Expiration timestamp (0 for no expiration)
     */
    function anchorCredential(
        bytes32 _credentialHash,
        bytes32 _didHash,
        string calldata _credentialType,
        uint256 _expiresAt
    ) public onlyTrustedIssuer {
        require(anchors[_credentialHash].issuedAt == 0, "Credential already anchored");
        require(_didHash != bytes32(0), "Invalid DID hash");
        require(bytes(_credentialType).length > 0, "Type required");
        
        anchors[_credentialHash] = CredentialAnchor({
            credentialHash: _credentialHash,
            didHash: _didHash,
            credentialType: _credentialType,
            issuedAt: block.timestamp,
            expiresAt: _expiresAt,
            revoked: false
        });
        
        agentCredentials[_didHash].push(_credentialHash);
        totalAnchors++;
        
        emit CredentialAnchored(_credentialHash, _didHash, msg.sender, _credentialType);
    }
    
    /**
     * @notice Batch anchor multiple credentials
     */
    function anchorCredentialsBatch(
        bytes32[] calldata _credentialHashes,
        bytes32[] calldata _didHashes,
        string[] calldata _credentialTypes,
        uint256[] calldata _expiresAts
    ) external onlyTrustedIssuer {
        require(
            _credentialHashes.length == _didHashes.length &&
            _didHashes.length == _credentialTypes.length &&
            _credentialTypes.length == _expiresAts.length,
            "Array length mismatch"
        );
        
        for (uint256 i = 0; i < _credentialHashes.length; i++) {
            anchorCredential(
                _credentialHashes[i],
                _didHashes[i],
                _credentialTypes[i],
                _expiresAts[i]
            );
        }
    }
    
    /**
     * @notice Revoke an anchored credential
     * @param _credentialHash Hash of the credential to revoke
     */
    function revokeCredential(bytes32 _credentialHash) external onlyTrustedIssuer {
        require(anchors[_credentialHash].issuedAt != 0, "Credential not found");
        require(!anchors[_credentialHash].revoked, "Already revoked");
        
        anchors[_credentialHash].revoked = true;
        
        emit CredentialRevoked(_credentialHash, msg.sender, block.timestamp);
    }
    
    /**
     * @notice Verify a credential hash exists and is valid
     * @param _credentialHash The credential hash to verify
     */
    function verifyCredential(bytes32 _credentialHash) 
        external 
        view 
        returns (bool valid, string memory reason) 
    {
        CredentialAnchor storage anchor = anchors[_credentialHash];
        
        if (anchor.issuedAt == 0) {
            return (false, "Credential not found");
        }
        
        if (anchor.revoked) {
            return (false, "Credential revoked");
        }
        
        if (anchor.expiresAt != 0 && block.timestamp > anchor.expiresAt) {
            return (false, "Credential expired");
        }
        
        return (true, "Valid");
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice Set trusted issuer status
     * @param _issuer Address to set
     * @param _trusted Trusted status
     */
    function setTrustedIssuer(address _issuer, bool _trusted) external onlyOwner {
        require(_issuer != address(0), "Invalid address");
        trustedIssuers[_issuer] = _trusted;
        emit IssuerTrusted(_issuer, _trusted);
    }
    
    // ============ View Functions ============
    
    function getAgentCredentialCount(bytes32 _didHash) external view returns (uint256) {
        return agentCredentials[_didHash].length;
    }
    
    function getAgentCredentials(bytes32 _didHash) external view returns (bytes32[] memory) {
        return agentCredentials[_didHash];
    }
    
    function getCredentialDetails(bytes32 _credentialHash) 
        external 
        view 
        returns (CredentialAnchor memory) 
    {
        return anchors[_credentialHash];
    }
}
