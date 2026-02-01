// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ClawMarkRegistry
 * @notice ClawMark - Core DID Registry
 * @dev Manages agent DIDs on Base L2
 */
contract ClawMarkRegistry is Ownable, ReentrancyGuard {
    
    // ============ Structs ============
    
    struct AgentRecord {
        bytes32 didHash;
        address controller;
        bytes publicKey;
        uint256 created;
        uint256 updated;
        uint256 stake;
        bool active;
        string platform;
    }
    
    struct RevocationEntry {
        bytes32 didHash;
        uint256 timestamp;
        string reason;
        address revokedBy;
    }
    
    // ============ State ============
    
    mapping(bytes32 => AgentRecord) public agents;
    mapping(address => bytes32[]) public controllerAgents;
    mapping(bytes32 => RevocationEntry) public revocations;
    
    uint256 public totalAgents;
    uint256 public activeAgents;
    uint256 public minimumStake;
    
    // ============ Events ============
    
    event AgentRegistered(
        bytes32 indexed didHash,
        address indexed controller,
        string platform,
        uint256 stake
    );
    
    event AgentUpdated(
        bytes32 indexed didHash,
        uint256 updatedAt
    );
    
    event AgentDeactivated(
        bytes32 indexed didHash,
        address indexed controller,
        string reason
    );
    
    event AgentReactivated(
        bytes32 indexed didHash,
        address indexed controller
    );
    
    event KeyRotated(
        bytes32 indexed didHash,
        uint256 rotatedAt
    );
    
    event StakeIncreased(
        bytes32 indexed didHash,
        uint256 newStake
    );
    
    event StakeSlashed(
        bytes32 indexed didHash,
        uint256 amount,
        string reason
    );
    
    event Revoked(
        bytes32 indexed didHash,
        address indexed revokedBy,
        string reason
    );
    
    // ============ Modifiers ============
    
    modifier onlyController(bytes32 _didHash) {
        require(agents[_didHash].controller == msg.sender, "Not controller");
        _;
    }
    
    modifier didExists(bytes32 _didHash) {
        require(agents[_didHash].created != 0, "DID not found");
        _;
    }
    
    modifier didActive(bytes32 _didHash) {
        require(agents[_didHash].active, "DID not active");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(uint256 _minimumStake) Ownable(msg.sender) {
        minimumStake = _minimumStake;
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Register a new agent DID
     * @param _didHash Hash of the full DID string
     * @param _publicKey Agent's public key
     * @param _platform Platform identifier (e.g., "moltbook", "clawdbot")
     */
    function register(
        bytes32 _didHash,
        bytes calldata _publicKey,
        string calldata _platform
    ) external payable nonReentrant returns (bytes32) {
        require(agents[_didHash].created == 0, "DID already exists");
        require(_publicKey.length > 0, "Public key required");
        require(bytes(_platform).length > 0, "Platform required");
        require(msg.value >= minimumStake, "Insufficient stake");
        
        agents[_didHash] = AgentRecord({
            didHash: _didHash,
            controller: msg.sender,
            publicKey: _publicKey,
            created: block.timestamp,
            updated: block.timestamp,
            stake: msg.value,
            active: true,
            platform: _platform
        });
        
        controllerAgents[msg.sender].push(_didHash);
        
        totalAgents++;
        activeAgents++;
        
        emit AgentRegistered(_didHash, msg.sender, _platform, msg.value);
        
        return _didHash;
    }
    
    /**
     * @notice Resolve a DID to its record
     * @param _didHash The DID hash to resolve
     */
    function resolve(bytes32 _didHash) 
        external 
        view 
        didExists(_didHash) 
        returns (AgentRecord memory) 
    {
        return agents[_didHash];
    }
    
    /**
     * @notice Update the public key (key rotation)
     * @param _didHash The DID to update
     * @param _newPublicKey New public key
     */
    function rotateKey(
        bytes32 _didHash,
        bytes calldata _newPublicKey
    ) 
        external 
        didExists(_didHash) 
        onlyController(_didHash) 
        didActive(_didHash) 
    {
        require(_newPublicKey.length > 0, "New key required");
        
        agents[_didHash].publicKey = _newPublicKey;
        agents[_didHash].updated = block.timestamp;
        
        emit KeyRotated(_didHash, block.timestamp);
        emit AgentUpdated(_didHash, block.timestamp);
    }
    
    /**
     * @notice Deactivate a DID (soft delete)
     * @param _didHash The DID to deactivate
     * @param _reason Reason for deactivation
     */
    function deactivate(
        bytes32 _didHash,
        string calldata _reason
    ) 
        external 
        didExists(_didHash) 
        onlyController(_didHash) 
        didActive(_didHash) 
    {
        agents[_didHash].active = false;
        agents[_didHash].updated = block.timestamp;
        
        activeAgents--;
        
        emit AgentDeactivated(_didHash, msg.sender, _reason);
    }
    
    /**
     * @notice Reactivate a previously deactivated DID
     * @param _didHash The DID to reactivate
     */
    function reactivate(
        bytes32 _didHash
    ) 
        external 
        didExists(_didHash) 
        onlyController(_didHash) 
    {
        require(!agents[_didHash].active, "Already active");
        
        agents[_didHash].active = true;
        agents[_didHash].updated = block.timestamp;
        
        activeAgents++;
        
        emit AgentReactivated(_didHash, msg.sender);
    }
    
    /**
     * @notice Add more stake to an agent
     * @param _didHash The DID to stake for
     */
    function increaseStake(
        bytes32 _didHash
    ) 
        external 
        payable 
        didExists(_didHash) 
        onlyController(_didHash) 
        didActive(_didHash) 
    {
        require(msg.value > 0, "Must send ETH");
        
        agents[_didHash].stake += msg.value;
        agents[_didHash].updated = block.timestamp;
        
        emit StakeIncreased(_didHash, agents[_didHash].stake);
    }
    
    /**
     * @notice Withdraw stake (only if above minimum)
     * @param _didHash The DID to withdraw from
     * @param _amount Amount to withdraw
     */
    function withdrawStake(
        bytes32 _didHash,
        uint256 _amount
    ) 
        external 
        nonReentrant
        didExists(_didHash) 
        onlyController(_didHash) 
    {
        require(_amount <= agents[_didHash].stake - minimumStake, "Cannot go below minimum");
        require(_amount > 0, "Amount must be > 0");
        
        agents[_didHash].stake -= _amount;
        agents[_didHash].updated = block.timestamp;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice Slash stake for bad behavior (only owner)
     * @param _didHash The DID to slash
     * @param _amount Amount to slash
     * @param _reason Reason for slashing
     */
    function slash(
        bytes32 _didHash,
        uint256 _amount,
        string calldata _reason
    ) 
        external 
        onlyOwner 
        didExists(_didHash) 
        didActive(_didHash) 
    {
        require(_amount <= agents[_didHash].stake, "Cannot slash more than stake");
        require(bytes(_reason).length > 0, "Reason required");
        
        agents[_didHash].stake -= _amount;
        agents[_didHash].updated = block.timestamp;
        
        emit StakeSlashed(_didHash, _amount, _reason);
        
        // Send slashed funds to owner (or could burn/treasury)
        (bool success, ) = payable(owner()).call{value: _amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @notice Revoke a DID (hard delete, only owner)
     * @param _didHash The DID to revoke
     * @param _reason Reason for revocation
     */
    function revoke(
        bytes32 _didHash,
        string calldata _reason
    ) 
        external 
        onlyOwner 
        didExists(_didHash) 
    {
        require(bytes(_reason).length > 0, "Reason required");
        
        revocations[_didHash] = RevocationEntry({
            didHash: _didHash,
            timestamp: block.timestamp,
            reason: _reason,
            revokedBy: msg.sender
        });
        
        if (agents[_didHash].active) {
            activeAgents--;
        }
        
        delete agents[_didHash];
        
        emit Revoked(_didHash, msg.sender, _reason);
    }
    
    /**
     * @notice Update minimum stake requirement
     * @param _newMinimum New minimum stake
     */
    function setMinimumStake(uint256 _newMinimum) external onlyOwner {
        minimumStake = _newMinimum;
    }
    
    // ============ View Functions ============
    
    function isActive(bytes32 _didHash) external view returns (bool) {
        return agents[_didHash].active;
    }
    
    function isRevoked(bytes32 _didHash) external view returns (bool) {
        return revocations[_didHash].timestamp != 0;
    }
    
    function getControllerAgents(address _controller) external view returns (bytes32[] memory) {
        return controllerAgents[_controller];
    }
    
    function getControllerAgentCount(address _controller) external view returns (uint256) {
        return controllerAgents[_controller].length;
    }
    
    // ============ Fallback ============
    
    receive() external payable {
        revert("Use increaseStake");
    }
}
