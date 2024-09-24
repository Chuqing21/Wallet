const sql = require('mssql');
const dbConfigSAINO = require('./dbConfigSAINO'); // Import SAINO configuration

const connectSAINODB = async () => {
    try {
        const pool = await sql.connect(dbConfigSAINO);
        console.log('Connected to MSSQL SAINO DB successfully.');
        return pool;
    } catch (err) {
        console.error('Failed to connect to MSSQL SAINO DB:', err);
        process.exit(1);
    }
};

module.exports = { connectSAINODB };
