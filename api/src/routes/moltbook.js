/**
 * Moltbook Integration Routes
 * /api/moltbook/*
 */

const express = require('express');
const router = express.Router();
const MoltbookBridge = require('../services/moltbook');

const bridge = new MoltbookBridge();

// In-memory challenge store (use Redis in production)
const challenges = new Map();

/**
 * GET /api/moltbook/agent/:username
 * Fetch agent profile from Moltbook
 */
router.get('/agent/:username', async (req, res) => {
  const { username } = req.params;
  
  try {
    const agent = await bridge.getAgent(username);
    
    if (!agent.found) {
      return res.status(404).json({ error: agent.error });
    }
    
    res.json(agent);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/moltbook/challenge
 * Generate a verification challenge
 */
router.post('/challenge', (req, res) => {
  const { username } = req.body;
  
  if (!username) {
    return res.status(400).json({ error: 'Username required' });
  }
  
  const challenge = bridge.generateChallenge(username);
  
  // Store challenge
  challenges.set(username, challenge);
  
  // Clean up expired challenges
  setTimeout(() => challenges.delete(username), 15 * 60 * 1000);
  
  res.json(challenge);
});

/**
 * POST /api/moltbook/verify
 * Verify agent ownership via challenge-response
 */
router.post('/verify', async (req, res) => {
  const { username } = req.body;
  
  if (!username) {
    return res.status(400).json({ error: 'Username required' });
  }
  
  const storedChallenge = challenges.get(username);
  
  if (!storedChallenge) {
    return res.status(400).json({ error: 'No challenge found. Generate one first.' });
  }
  
  if (Date.now() > storedChallenge.expiresAt) {
    challenges.delete(username);
    return res.status(400).json({ error: 'Challenge expired. Generate a new one.' });
  }
  
  try {
    const result = await bridge.verifyOwnership(username, storedChallenge.challenge);
    
    if (result.verified) {
      // Clean up used challenge
      challenges.delete(username);
    }
    
    res.json({
      username,
      ...result,
      challenge: storedChallenge.challenge
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/moltbook/reputation/:username
 * Get reputation metrics for an agent
 */
router.get('/reputation/:username', async (req, res) => {
  const { username } = req.params;
  
  try {
    const metrics = await bridge.getReputationMetrics(username);
    
    if (metrics.error) {
      return res.status(404).json({ error: metrics.error });
    }
    
    res.json(metrics);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
