const { GoogleGenAI, Type } = require("@google/genai");
const { createResponse } = require("./attest-verify");

// Version: CommonJS v3 - with App Attest verification
const genAI = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || '' });

// Whether to enforce attestation (reject requests without valid attestation)
const ENFORCE_ATTESTATION = process.env.ENFORCE_ATTESTATION !== 'false';

// Models in order of preference (lite first, then standard)
const MODELS = ["gemini-2.5-flash", "gemini-2.5-flash-lite", "gemma-3-27b-it"];

async function generateWords(topic, modelIndex = 0) {
    if (modelIndex >= MODELS.length) {
        throw new Error('All models exhausted - quota exceeded on all');
    }

    const model = MODELS[modelIndex];
    console.log(`Trying model: ${model}`);

    const prompt = `You are an assistant for an imposter-style party game. Your task is to generate a list of 100 specific, named examples for a given topic. Avoid general terms, categories, or related concepts.

For example:
- If the topic is "Marvel Superheroes", good examples include: ["Iron Man", "Captain America", "Thor", "Hulk", "Spider-Man", "Black Widow", "Hawkeye", "Scarlet Witch", ...].
- Bad examples for "Marvel Superheroes" would be: ["Superhero", "Villain", "Avenger", "Sidekick", "Costume"].

Now, generate a list of 100 specific, named examples for the topic: '${topic}'.`;

    try {
        let result;

        // Gemma 3 doesn't support JSON mode, so we must prompt for it and parse text
        if (model.includes('gemma')) {
            const gemmaPrompt = prompt + `\n\nRETURN ONLY RAW JSON. NO MARKDOWN. NO BACKTICKS. Format: {"words": ["word1", "word2"...]}`;
            result = await genAI.models.generateContent({
                model: model,
                contents: gemmaPrompt,
            });
        } else {
            // Gemini supports native JSON mode
            result = await genAI.models.generateContent({
                model: model,
                contents: prompt,
                config: {
                    responseMimeType: "application/json",
                    responseSchema: {
                        type: Type.OBJECT,
                        properties: {
                            words: {
                                type: Type.ARRAY,
                                items: {
                                    type: Type.STRING,
                                    description: "A single, specific, named example related to the topic."
                                }
                            }
                        }
                    }
                }
            });
        }

        if (!result.text) {
            throw new Error('No text in response');
        }

        // Clean up response if it has markdown code blocks (common in instruction tuned models)
        let cleanText = result.text ? result.text.trim() : '';
        cleanText = cleanText.replace(/```json/g, '').replace(/```/g, '').trim();

        return { json: JSON.parse(cleanText), model };
    } catch (error) {
        // Check if it's a quota error or bad request
        if (error.status === 429 || error.message?.includes('429') || error.message?.includes('quota')) {
            console.log(`Quota exceeded on ${model}, trying fallback...`);
            return generateWords(topic, modelIndex + 1);
        }
        // If JSON parsing fails or model doesn't support JSON mode, try next model
        if (error.message?.includes('JSON mode is not enabled') || error instanceof SyntaxError) {
            console.log(`JSON error on ${model}: ${error.message}. Trying fallback...`);
            return generateWords(topic, modelIndex + 1);
        }
        throw error;
    }
}


exports.handler = async (event, context) => {
    // Handle CORS preflight request
    if (event.requestContext?.http?.method === 'OPTIONS' || event.httpMethod === 'OPTIONS') {
        return createResponse(200, {});
    }

    const method = event.requestContext?.http?.method || event.httpMethod;
    if (method !== 'POST') {
        return createResponse(405, { error: 'Method not allowed' });
    }

    // === JWT SESSION VERIFICATION ===
    // Lightweight check: Verify the session token issued by the handshake
    const authHeader = event.headers?.['authorization'] || event.headers?.['Authorization'];

    if (ENFORCE_ATTESTATION) {
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return createResponse(401, {
                error: 'Unauthorized',
                message: 'Missing or invalid session token. Please perform handshake again.',
                reason: 'MISSING_TOKEN'
            });
        }

        const token = authHeader.split(' ')[1];
        const jwt = require('jsonwebtoken');
        const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-key-change-in-prod';

        try {
            jwt.verify(token, JWT_SECRET);
            console.log('Session token verified successfully');
        } catch (err) {
            console.log('Session token verification failed:', err.message);
            return createResponse(401, {
                error: 'Unauthorized',
                message: 'Session expired or invalid. Please perform handshake again.',
                reason: 'INVALID_TOKEN',
                details: err.message
            });
        }
    }
    // === END JWT VERIFICATION ===

    let body;
    try {
        body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    } catch (e) {
        return createResponse(400, { error: 'Invalid JSON body' });
    }

    const { topic } = body || {};
    console.log(`Received request for topic: ${topic}`);

    if (!topic || typeof topic !== 'string' || topic.trim().length === 0) {
        return createResponse(400, { error: 'Topic is required and must be a non-empty string' });
    }

    if (topic.length > 100) {
        return createResponse(400, { error: 'Topic is too long (max 100 chars)' });
    }

    // Basic sanitization: allow letters, numbers, spaces, and basic punctuation
    const sanitizedTopic = topic.replace(/[^a-zA-Z0-9\s\-_.,!?]/g, '').trim();

    try {
        const { json, model } = await generateWords(sanitizedTopic);
        console.log(`Successfully generated ${json.words?.length} words using ${model}.`);
        return createResponse(200, json);
    } catch (error) {
        console.error('Error in backend generation:', error);
        return createResponse(500, {
            error: 'Failed to generate words from Gemini',
            details: error.message,
            stack: error.stack
        });
    }
};
