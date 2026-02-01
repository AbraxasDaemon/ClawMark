/**
 * Credential Routes
 */

const express = require('express');
const router = express.Router();
const crypto = require('crypto');

// In-memory storage
const credentialStore = new Map();

/**
 * @route POST /v1/credentials/anchor
 * @desc Anchor a credential hash on-chain
 */
router.post('/anchor', async (req, res) => {
  try {
    const { credentialHash, didHash, credentialType, expiresAt } = req.body;

    if (!credentialHash || !didHash || !credentialType) {
      return res.status(400).json({
        error: 'Missing required fields: credentialHash, didHash, credentialType'
      });
    }

    // Check if already anchored
    if (credentialStore.has(credentialHash)) {
      return res.status(409).json({
        error: 'Credential already anchored',
        credentialHash
      });
    }

    // Store
    const anchor = {
      credentialHash,
      didHash,
      credentialType,
      issuedAt: new Date(),
      expiresAt: expiresAt ? new Date(expiresAt) : null,
      revoked: false
    };

    credentialStore.set(credentialHash, anchor);

    res.status(201).json({
      credentialHash,
      status: 'anchored',
      issuedAt: anchor.issuedAt,
      message: 'Credential anchored successfully'
    });

  } catch (error) {
    console.error('Anchor error:', error);
    res.status(500).json({ error: 'Failed to anchor credential' });
  }
});

/**
 * @route POST /v1/credentials/verify
 * @desc Verify a credential
 */
router.post('/verify', async (req, res) => {
  try {
    const { credentialHash } = req.body;

    if (!credentialHash) {
      return res.status(400).json({ error: 'credentialHash required' });
    }

    const anchor = credentialStore.get(credentialHash);

    if (!anchor) {
      return res.status(404).json({
        valid: false,
        reason: 'Credential not found'
      });
    }

    // Check revocation
    if (anchor.revoked) {
      return res.json({
        valid: false,
        reason: 'Credential revoked',
        anchoredAt: anchor.issuedAt
      });
    }

    // Check expiration
    if (anchor.expiresAt && new Date() > anchor.expiresAt) {
      return res.json({
        valid: false,
        reason: 'Credential expired',
        anchoredAt: anchor.issuedAt,
        expiredAt: anchor.expiresAt
      });
    }

    res.json({
      valid: true,
      reason: 'Valid',
      anchoredAt: anchor.issuedAt,
      expiresAt: anchor.expiresAt,
      didHash: anchor.didHash,
      type: anchor.credentialType
    });

  } catch (error) {
    console.error('Verification error:', error);
    res.status(500).json({ error: 'Failed to verify credential' });
  }
});

/**
 * @route POST /v1/credentials/revoke
 * @desc Revoke a credential
 */
router.post('/revoke', async (req, res) => {
  try {
    const { credentialHash, reason } = req.body;

    if (!credentialHash) {
      return res.status(400).json({ error: 'credentialHash required' });
    }

    const anchor = credentialStore.get(credentialHash);

    if (!anchor) {
      return res.status(404).json({ error: 'Credential not found' });
    }

    anchor.revoked = true;
    anchor.revokedAt = new Date();
    anchor.revocationReason = reason || 'No reason provided';

    res.json({
      credentialHash,
      status: 'revoked',
      revokedAt: anchor.revokedAt,
      reason: anchor.revocationReason
    });

  } catch (error) {
    console.error('Revocation error:', error);
    res.status(500).json({ error: 'Failed to revoke credential' });
  }
});

/**
 * @route GET /v1/credentials/:didHash
 * @desc Get all credentials for a DID
 */
router.get('/agent/:didHash', async (req, res) => {
  try {
    const { didHash } = req.params;
    
    const credentials = Array.from(credentialStore.values())
      .filter(c => c.didHash === didHash)
      .map(c => ({
        credentialHash: c.credentialHash,
        type: c.credentialType,
        issuedAt: c.issuedAt,
        expiresAt: c.expiresAt,
        revoked: c.revoked,
        status: c.revoked ? 'revoked' : (c.expiresAt && new Date() > c.expiresAt ? 'expired' : 'active')
      }));

    res.json({
      didHash,
      credentials,
      count: credentials.length
    });

  } catch (error) {
    console.error('List error:', error);
    res.status(500).json({ error: 'Failed to list credentials' });
  }
});

module.exports = router;
