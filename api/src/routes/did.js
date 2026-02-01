/**
 * DID Routes
 */

const express = require('express');
const router = express.Router();
const { ethers } = require('ethers');

// In-memory storage for MVP (replace with database in production)
const didStore = new Map();

/**
 * @route POST /v1/did/register
 * @desc Register a new agent DID
 */
router.post('/register', async (req, res) => {
  try {
    const { platform, agentName, publicKey, stake } = req.body;

    // Validation
    if (!platform || !agentName || !publicKey) {
      return res.status(400).json({
        error: 'Missing required fields: platform, agentName, publicKey'
      });
    }

    // Generate DID
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 10);
    const sanitizedName = agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
    const did = `did:agent:${platform}:${sanitizedName}-${timestamp}-${random}`;
    const didHash = ethers.keccak256(ethers.toUtf8Bytes(did));

    // Create DID document
    const didDocument = {
      '@context': [
        'https://www.w3.org/ns/did/v1',
        'https://agentverify.io/v1'
      ],
      id: did,
      created: new Date().toISOString(),
      controller: `did:key:${publicKey}`,
      verificationMethod: [{
        id: `${did}#keys-1`,
        type: 'Ed25519VerificationKey2020',
        controller: did,
        publicKeyMultibase: publicKey
      }],
      authentication: ['#keys-1'],
      assertionMethod: ['#keys-1'],
      service: [{
        id: '#avs',
        type: 'AgentVerificationService',
        serviceEndpoint: 'https://api.agentverify.io/v1'
      }],
      agentMetadata: {
        name: agentName,
        platform,
        created: new Date().toISOString()
      }
    };

    // Store
    didStore.set(did, {
      did,
      didHash,
      document: didDocument,
      stake: stake || '0',
      active: true,
      createdAt: new Date()
    });

    res.status(201).json({
      did,
      didHash,
      document: didDocument,
      message: 'DID registered successfully'
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Failed to register DID' });
  }
});

/**
 * @route GET /v1/did/:did
 * @desc Resolve a DID to its document
 */
router.get('/:did', async (req, res) => {
  try {
    const { did } = req.params;

    // Check local store
    const record = didStore.get(did);
    if (record) {
      return res.json(record.document);
    }

    // Try to resolve from on-chain (when implemented)
    // const onChainDoc = await resolveFromChain(did);
    // if (onChainDoc) return res.json(onChainDoc);

    res.status(404).json({ error: 'DID not found' });

  } catch (error) {
    console.error('Resolution error:', error);
    res.status(500).json({ error: 'Failed to resolve DID' });
  }
});

/**
 * @route GET /v1/did/:did/status
 * @desc Get DID status
 */
router.get('/:did/status', async (req, res) => {
  try {
    const { did } = req.params;
    const record = didStore.get(did);

    if (!record) {
      return res.status(404).json({ error: 'DID not found' });
    }

    res.json({
      did,
      didHash: record.didHash,
      active: record.active,
      stake: record.stake,
      createdAt: record.createdAt
    });

  } catch (error) {
    console.error('Status error:', error);
    res.status(500).json({ error: 'Failed to get status' });
  }
});

/**
 * @route POST /v1/did/:did/deactivate
 * @desc Deactivate a DID
 */
router.post('/:did/deactivate', async (req, res) => {
  try {
    const { did } = req.params;
    const record = didStore.get(did);

    if (!record) {
      return res.status(404).json({ error: 'DID not found' });
    }

    // In production, verify signature
    record.active = false;
    record.document.active = false;

    res.json({
      did,
      status: 'deactivated',
      message: 'DID deactivated successfully'
    });

  } catch (error) {
    console.error('Deactivation error:', error);
    res.status(500).json({ error: 'Failed to deactivate DID' });
  }
});

/**
 * @route GET /v1/did
 * @desc List all DIDs (paginated)
 */
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const allDids = Array.from(didStore.values());
    const paginatedDids = allDids.slice(offset, offset + limit);

    res.json({
      dids: paginatedDids.map(r => ({
        did: r.did,
        name: r.document.agentMetadata.name,
        platform: r.document.agentMetadata.platform,
        active: r.active,
        createdAt: r.createdAt
      })),
      pagination: {
        page,
        limit,
        total: allDids.length,
        pages: Math.ceil(allDids.length / limit)
      }
    });

  } catch (error) {
    console.error('List error:', error);
    res.status(500).json({ error: 'Failed to list DIDs' });
  }
});

module.exports = router;
