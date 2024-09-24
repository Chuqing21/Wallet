const appSAINO = require('./appSAINO');
const port = process.env.PORT_SAINO || 3001; // Different port for SAINO API

// Start server
appSAINO.listen(port, () => {
    console.log(`SAINO API server is running on http://localhost:${port}`);
});
