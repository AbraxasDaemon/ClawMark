/**
 * Reputation Routes
 */

const express = require('express');
const router = express.Router();

// In-memory storage
const reputationStore = new Map();

// Tier thresholds
const TIERS = {
  unrated: { min: 0, max: 199 },
  bronze: { min: 200, max: 399 },
  silver: { min: 400, max: 699 },
  gold: { min: 700, max: 899 },
  platinum: { min: 900, max: 1000 }
};

function calculateTier(score) {
  for (const [tier, range] of Object.entries(TIERS)) {
    if (score >= range.min && score <= range.max) {
      return tier;
    }
  }
  return 'unrated';
}

/**
 * @route GET /v1/reputation/:did
 * @desc Get reputation score for an agent
 */
router.get('/:did', async (req, res) => {
  try {
    const { did } = req.params;
    
    let reputation = reputationStore.get(did);
    
    // If no reputation exists, return default
    if (!reputation) {
      reputation = {
        did,
        score: 0,
        maxScore: 1000,
        tier: 'unrated',
        metrics: {
          reliability: 0,
          taskCompletion: 0,
          security: 0,
          timeliness: 0,
          peerEndorsements: 0
        },
        interactions: {
          total: 0,
          successful: 0,
          disputed: 0,
          failed: 0
        },
        updatedAt: null
      };
    }

    res.json(reputation);

  } catch (error) {
    console.error('Reputation error:', error);
    res.status(500).json({ error: 'Failed to get reputation' });
  }
});

/**
 * @route POST /v1/reputation/:did
 * @desc Update reputation score (oracle only)
 */
router.post('/:did', async (req, res) => {
  try {
    const { did } = req.params;
    const {
      score,
      reliability,
      taskCompletion,
      security,
      timeliness,
      peerEndorsements,
      totalInteractions,
      successfulInteractions
    } = req.body;

    // Validation
    if (score < 0 || score > 1000) {
      return res.status(400).json({ error: 'Score must be between 0 and 1000' });
    }

    const tier = calculateTier(score);

    const reputation = {
      did,
      score,
      maxScore: 1000,
      tier,
      metrics: {
        reliability: reliability || 0,
        taskCompletion: taskCompletion || 0,
        security: security || 0,
        timeliness: timeliness || 0,
        peerEndorsements: peerEndorsements || 0
      },
      interactions: {
        total: totalInteractions || 0,
        successful: successfulInteractions || 0,
        disputed: 0,
        failed: (totalInteractions || 0) - (successfulInteractions || 0)
      },
      updatedAt: new Date()
    };

    reputationStore.set(did, reputation);

    res.json({
      did,
      score,
      tier,
      updatedAt: reputation.updatedAt,
      message: 'Reputation updated successfully'
    });

  } catch (error) {
    console.error('Update error:', error);
    res.status(500).json({ error: 'Failed to update reputation' });
  }
});

/**
 * @route GET /v1/reputation/leaderboard
 * @desc Get top agents by reputation
 */
router.get('/leaderboard', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const tier = req.query.tier;

    let agents = Array.from(reputationStore.values());

    if (tier) {
      agents = agents.filter(a => a.tier === tier);
    }

    // Sort by score descending
    agents.sort((a, b) => b.score - a.score);

    const topAgents = agents.slice(0, limit);

    res.json({
      agents: topAgents,
      count: topAgents.length,
      filters: { tier }
    });

  } catch (error) {
    console.error('Leaderboard error:', error);
    res.status(500).json({ error: 'Failed to get leaderboard' });
  }
});

/**
 * @route GET /v1/reputation/tiers
 * @desc Get tier definitions
 */
router.get('/tiers', async (req, res) => {
  res.json({
    tiers: TIERS,
    maxScore: 1000
  });
});

module.exports = router;
