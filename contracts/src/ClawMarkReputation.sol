// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ClawMarkReputation
 * @notice Reputation score anchoring (oracle-updateable)
 * @dev Stores reputation scores on-chain with oracle updates
 */
contract ClawMarkReputation is Ownable {
    
    constructor() Ownable(msg.sender) {}
    
    // ============ Structs ============
    
    struct ReputationScore {
        bytes32 didHash;
        uint256 score;
        uint256 maxScore;
        string tier;
        uint256 updatedAt;
        address updatedBy;
        uint256 version;
    }
    
    struct ReputationMetrics {
        uint256 reliability;
        uint256 taskCompletion;
        uint256 security;
        uint256 timeliness;
        uint256 peerEndorsements;
        uint256 totalInteractions;
        uint256 successfulInteractions;
    }
    
    // ============ State ============
    
    // didHash => current score
    mapping(bytes32 => ReputationScore) public scores;
    
    // didHash => version => historical score
    mapping(bytes32 => mapping(uint256 => ReputationScore)) public scoreHistory;
    
    // didHash => metrics
    mapping(bytes32 => ReputationMetrics) public metrics;
    
    // oracle => isAuthorized
    mapping(address => bool) public authorizedOracles;
    
    // Tier thresholds
    uint256 public bronzeThreshold = 200;
    uint256 public silverThreshold = 400;
    uint256 public goldThreshold = 700;
    uint256 public platinumThreshold = 900;
    
    uint256 public constant MAX_SCORE = 1000;
    
    // ============ Events ============
    
    event ScoreUpdated(
        bytes32 indexed didHash,
        uint256 score,
        string tier,
        address indexed updatedBy,
        uint256 version
    );
    
    event MetricsUpdated(
        bytes32 indexed didHash,
        uint256 reliability,
        uint256 taskCompletion,
        uint256 security
    );
    
    event OracleAuthorized(
        address indexed oracle,
        bool authorized
    );
    
    event TierThresholdsUpdated(
        uint256 bronze,
        uint256 silver,
        uint256 gold,
        uint256 platinum
    );
    
    // ============ Modifiers ============
    
    modifier onlyOracle() {
        require(authorizedOracles[msg.sender] || msg.sender == owner(), "Not authorized oracle");
        _;
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Update reputation score for an agent
     * @param _didHash The agent's DID hash
     * @param _score New score (0-1000)
     * @param _reliability Reliability metric (0-100)
     * @param _taskCompletion Task completion metric (0-100)
     * @param _security Security metric (0-100)
     * @param _timeliness Timeliness metric (0-100)
     * @param _peerEndorsements Number of peer endorsements
     */
    function updateScore(
        bytes32 _didHash,
        uint256 _score,
        uint256 _reliability,
        uint256 _taskCompletion,
        uint256 _security,
        uint256 _timeliness,
        uint256 _peerEndorsements
    ) external onlyOracle {
        require(_score <= MAX_SCORE, "Score exceeds max");
        require(_reliability <= 100, "Reliability exceeds 100");
        require(_taskCompletion <= 100, "Task completion exceeds 100");
        require(_security <= 100, "Security exceeds 100");
        require(_timeliness <= 100, "Timeliness exceeds 100");
        
        // Determine tier
        string memory tier = calculateTier(_score);
        
        // Get current version
        uint256 newVersion = scores[_didHash].version + 1;
        
        // Archive current score if exists
        if (scores[_didHash].updatedAt != 0) {
            scoreHistory[_didHash][scores[_didHash].version] = scores[_didHash];
        }
        
        // Update score
        scores[_didHash] = ReputationScore({
            didHash: _didHash,
            score: _score,
            maxScore: MAX_SCORE,
            tier: tier,
            updatedAt: block.timestamp,
            updatedBy: msg.sender,
            version: newVersion
        });
        
        // Update metrics
        metrics[_didHash] = ReputationMetrics({
            reliability: _reliability,
            taskCompletion: _taskCompletion,
            security: _security,
            timeliness: _timeliness,
            peerEndorsements: _peerEndorsements,
            totalInteractions: metrics[_didHash].totalInteractions,
            successfulInteractions: metrics[_didHash].successfulInteractions
        });
        
        emit ScoreUpdated(_didHash, _score, tier, msg.sender, newVersion);
        emit MetricsUpdated(_didHash, _reliability, _taskCompletion, _security);
    }
    
    /**
     * @notice Update interaction counts
     * @param _didHash The agent's DID hash
     * @param _total Total interactions
     * @param _successful Successful interactions
     */
    function updateInteractions(
        bytes32 _didHash,
        uint256 _total,
        uint256 _successful
    ) external onlyOracle {
        require(_successful <= _total, "Successful cannot exceed total");
        
        metrics[_didHash].totalInteractions = _total;
        metrics[_didHash].successfulInteractions = _successful;
    }
    
    /**
     * @notice Calculate tier from score
     */
    function calculateTier(uint256 _score) public view returns (string memory) {
        if (_score >= platinumThreshold) return "platinum";
        if (_score >= goldThreshold) return "gold";
        if (_score >= silverThreshold) return "silver";
        if (_score >= bronzeThreshold) return "bronze";
        return "unrated";
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice Set authorized oracle status
     */
    function setAuthorizedOracle(address _oracle, bool _authorized) external onlyOwner {
        require(_oracle != address(0), "Invalid address");
        authorizedOracles[_oracle] = _authorized;
        emit OracleAuthorized(_oracle, _authorized);
    }
    
    /**
     * @notice Update tier thresholds
     */
    function setTierThresholds(
        uint256 _bronze,
        uint256 _silver,
        uint256 _gold,
        uint256 _platinum
    ) external onlyOwner {
        require(_bronze < _silver && _silver < _gold && _gold < _platinum, "Invalid thresholds");
        require(_platinum <= MAX_SCORE, "Platinum exceeds max");
        
        bronzeThreshold = _bronze;
        silverThreshold = _silver;
        goldThreshold = _gold;
        platinumThreshold = _platinum;
        
        emit TierThresholdsUpdated(_bronze, _silver, _gold, _platinum);
    }
    
    // ============ View Functions ============
    
    function getScore(bytes32 _didHash) external view returns (ReputationScore memory) {
        return scores[_didHash];
    }
    
    function getMetrics(bytes32 _didHash) external view returns (ReputationMetrics memory) {
        return metrics[_didHash];
    }
    
    function getHistoricalScore(bytes32 _didHash, uint256 _version) 
        external 
        view 
        returns (ReputationScore memory) 
    {
        return scoreHistory[_didHash][_version];
    }
    
    function isTrusted(bytes32 _didHash) external view returns (bool) {
        return scores[_didHash].score >= silverThreshold;
    }
    
    function getCompletionRate(bytes32 _didHash) external view returns (uint256) {
        ReputationMetrics storage m = metrics[_didHash];
        if (m.totalInteractions == 0) return 0;
        return (m.successfulInteractions * 100) / m.totalInteractions;
    }
}
