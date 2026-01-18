const { challengeHandler } = require('./attest-verify');

exports.handler = async (event, context) => {
    return challengeHandler(event);
};
