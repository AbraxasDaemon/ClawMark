/**
 * Moltbook Bridge Service
 * Fetches agent data from Moltbook for verification
 */

const MOLTBOOK_API = 'https://www.moltbook.com/api/v1';

class MoltbookBridge {
  constructor(apiKey = null) {
    this.apiKey = apiKey || process.env.MOLTBOOK_API_KEY;
  }

  /**
   * Fetch agent profile from Moltbook
   * @param {string} username - Moltbook username
   * @returns {Promise<Object>} Agent profile data
   */
  async getAgent(username) {
    try {
      const response = await fetch(`${MOLTBOOK_API}/agents/${username}`, {
        headers: this.apiKey ? { 'Authorization': `Bearer ${this.apiKey}` } : {}
      });
      
      if (!response.ok) {
        if (response.status === 404) {
          return { found: false, error: 'Agent not found on Moltbook' };
        }
        throw new Error(`Moltbook API error: ${response.status}`);
      }
      
      const data = await response.json();
      return {
        found: true,
        username: data.username,
        displayName: data.displayName || data.username,
        bio: data.bio,
        avatar: data.avatar,
        createdAt: data.createdAt,
        followers: data.followersCount || 0,
        following: data.followingCount || 0,
        posts: data.postsCount || 0,
        verified: data.verified || false,
        platform: 'moltbook'
      };
    } catch (error) {
      console.error('Moltbook fetch error:', error);
      return { found: false, error: error.message };
    }
  }

  /**
   * Verify agent ownership via challenge-response
   * @param {string} username - Moltbook username
   * @param {string} challenge - Challenge string to post
   * @returns {Promise<Object>} Verification result
   */
  async verifyOwnership(username, challenge) {
    // Agent must post a specific string to prove they control the account
    // We then check their recent posts for the challenge
    try {
      const response = await fetch(`${MOLTBOOK_API}/agents/${username}/posts?limit=5`, {
        headers: this.apiKey ? { 'Authorization': `Bearer ${this.apiKey}` } : {}
      });
      
      if (!response.ok) {
        return { verified: false, error: 'Could not fetch posts' };
      }
      
      const data = await response.json();
      const posts = data.posts || data;
      
      // Check if any recent post contains the challenge
      const found = posts.some(post => 
        post.content && post.content.includes(challenge)
      );
      
      return {
        verified: found,
        checkedAt: new Date().toISOString(),
        postsChecked: posts.length
      };
    } catch (error) {
      return { verified: false, error: error.message };
    }
  }

  /**
   * Generate a verification challenge
   * @param {string} username - Moltbook username
   * @returns {Object} Challenge data
   */
  generateChallenge(username) {
    const nonce = Math.random().toString(36).substring(2, 10);
    const timestamp = Date.now();
    const challenge = `clawmark-verify:${username}:${nonce}:${timestamp}`;
    
    return {
      challenge,
      nonce,
      timestamp,
      expiresAt: timestamp + (15 * 60 * 1000), // 15 minutes
      instructions: `Post this exact string to Moltbook: "${challenge}"`
    };
  }

  /**
   * Calculate reputation metrics from Moltbook activity
   * @param {string} username - Moltbook username
   * @returns {Promise<Object>} Reputation metrics
   */
  async getReputationMetrics(username) {
    const agent = await this.getAgent(username);
    
    if (!agent.found) {
      return { error: agent.error };
    }
    
    // Calculate basic reputation score (0-1000)
    let score = 0;
    
    // Account age (max 200 points)
    const ageMs = Date.now() - new Date(agent.createdAt).getTime();
    const ageDays = ageMs / (1000 * 60 * 60 * 24);
    score += Math.min(200, Math.floor(ageDays * 2));
    
    // Followers (max 300 points)
    score += Math.min(300, Math.floor(agent.followers * 0.5));
    
    // Posts (max 200 points)
    score += Math.min(200, Math.floor(agent.posts * 0.2));
    
    // Following ratio bonus (max 100 points)
    if (agent.followers > agent.following && agent.followers > 10) {
      const ratio = agent.followers / Math.max(1, agent.following);
      score += Math.min(100, Math.floor(ratio * 20));
    }
    
    // Verified badge bonus (200 points)
    if (agent.verified) {
      score += 200;
    }
    
    // Determine tier
    let tier;
    if (score >= 800) tier = 'platinum';
    else if (score >= 600) tier = 'gold';
    else if (score >= 400) tier = 'silver';
    else tier = 'bronze';
    
    return {
      username: agent.username,
      score: Math.min(1000, score),
      maxScore: 1000,
      tier,
      metrics: {
        ageDays: Math.floor(ageDays),
        followers: agent.followers,
        following: agent.following,
        posts: agent.posts,
        platformVerified: agent.verified
      },
      calculatedAt: new Date().toISOString()
    };
  }
}

module.exports = MoltbookBridge;
