const crypto = require('crypto');

// In-memory challenge store (in production, use Redis or DynamoDB with TTL)
// Challenges are valid for 5 minutes
const challengeStore = new Map();
const CHALLENGE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Generates a cryptographically secure challenge for App Attest.
 * @returns {{ challenge: string, timestamp: number }}
 */
function generateChallenge() {
    const challenge = crypto.randomBytes(32).toString('base64url');
    const timestamp = Date.now();
    challengeStore.set(challenge, timestamp);
    return { challenge, timestamp };
}

/**
 * Validates that a challenge was recently issued.
 * @param {string} challenge 
 * @returns {boolean}
 */
function validateChallenge(challenge) {
    const timestamp = challengeStore.get(challenge);
    if (!timestamp) {
        return false;
    }

    const age = Date.now() - timestamp;
    if (age > CHALLENGE_TTL_MS) {
        challengeStore.delete(challenge);
        return false;
    }

    // Challenge is valid - remove it (one-time use)
    challengeStore.delete(challenge);
    return true;
}

/**
 * Cleans up expired challenges from the store.
 */
function cleanupExpiredChallenges() {
    const now = Date.now();
    for (const [challenge, timestamp] of challengeStore.entries()) {
        if (now - timestamp > CHALLENGE_TTL_MS) {
            challengeStore.delete(challenge);
        }
    }
}

// Run cleanup periodically (in Lambda, this happens on cold starts)
setInterval(cleanupExpiredChallenges, CHALLENGE_TTL_MS);

/**
 * Verifies an App Attest token.
 * 
 * Note: Full verification requires:
 * 1. Decoding the CBOR attestation object
 * 2. Verifying the certificate chain against Apple's root CA
 * 3. Verifying the nonce matches SHA256(challenge)
 * 4. Storing the public key for future assertion verification
 * 
 * For a simplified implementation, we validate the token format
 * and log for monitoring. Full verification can be added later.
 * 
 * @param {string} attestToken - Base64-encoded attestation token
 * @returns {{ valid: boolean, error?: string, details?: object }}
 */
function verifyAttestToken(attestToken) {
    if (!attestToken || typeof attestToken !== 'string') {
        return {
            valid: false,
            error: 'Missing attestation token',
            details: { reason: 'MISSING_TOKEN' }
        };
    }

    // Basic format validation
    if (attestToken.length < 100) {
        return {
            valid: false,
            error: 'Attestation token too short',
            details: { reason: 'TOKEN_TOO_SHORT', length: attestToken.length }
        };
    }

    // Try to decode as base64
    try {
        const decoded = Buffer.from(attestToken, 'base64');
        if (decoded.length < 50) {
            return {
                valid: false,
                error: 'Decoded attestation too short',
                details: { reason: 'DECODED_TOO_SHORT', length: decoded.length }
            };
        }

        // Log attestation for monitoring (in production, do full CBOR verification)
        console.log(`Attestation received: ${decoded.length} bytes`);

        // For now, accept any properly-formatted token
        // TODO: Implement full Apple attestation verification
        return {
            valid: true,
            details: {
                decodedLength: decoded.length,
                note: 'Basic format validation only. Full verification pending.'
            }
        };
    } catch (e) {
        return {
            valid: false,
            error: 'Invalid base64 encoding',
            details: { reason: 'INVALID_BASE64', message: e.message }
        };
    }
}

// Helper to create Lambda response with CORS headers
function createResponse(statusCode, body) {
    return {
        statusCode,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-App-Attest'
        },
        body: JSON.stringify(body)
    };
}

/**
 * Lambda handler for challenge endpoint.
 */
async function challengeHandler(event) {
    // Handle CORS preflight
    if (event.requestContext?.http?.method === 'OPTIONS' || event.httpMethod === 'OPTIONS') {
        return createResponse(200, {});
    }

    const method = event.requestContext?.http?.method || event.httpMethod;
    if (method !== 'GET') {
        return createResponse(405, { error: 'Method not allowed' });
    }

    const { challenge, timestamp } = generateChallenge();
    console.log(`Challenge generated: ${challenge.substring(0, 8)}... at ${new Date(timestamp).toISOString()}`);

    return createResponse(200, {
        challenge,
        expiresIn: CHALLENGE_TTL_MS / 1000
    });
}

module.exports = {
    generateChallenge,
    validateChallenge,
    verifyAttestToken,
    createResponse,
    challengeHandler
};
