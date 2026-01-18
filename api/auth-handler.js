const jwt = require('jsonwebtoken');
const { verifyAttestToken } = require('./attest-verify');

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRATION = '1h'; // Session valid for 1 hour

exports.verifyDeviceHandler = async (event) => {
    console.log('Received verify-device request');

    try {
        const attestToken = event.headers['X-App-Attest'] || event.headers['x-app-attest'];

        if (!attestToken) {
            return {
                statusCode: 400,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ error: 'Missing X-App-Attest header' })
            };
        }

        // 1. Verify App Attest Token (Heavy Operation)
        const verificationResult = await verifyAttestToken(attestToken);

        // In a real app, you might use verificationResult.publicKey to identify the device
        // and store it in a DB to track this specific installation.
        const deviceId = verificationResult.credId || 'unknown-device';

        // 2. Issue Session JWT
        const token = jwt.sign(
            {
                sub: deviceId, // Subject = Device Credential ID
                scope: 'api:access',
                verified: true
            },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRATION }
        );

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST',
                'Access-Control-Allow-Headers': 'Content-Type,X-App-Attest,Authorization'
            },
            body: JSON.stringify({
                token: token,
                expiresIn: 3600
            })
        };

    } catch (error) {
        console.error('Handshake failed:', error);
        return {
            statusCode: 403, // Forbidden
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                error: 'Handshake failed',
                details: error.message
            })
        };
    }
};
