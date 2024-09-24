const sql = require('mssql');
const { dbConfig } = require('../config/config');

const connectDB = async () => {
    try {
        const pool = await sql.connect(dbConfig);
        console.log('Connected to MSSQL successfully.');
        return pool;
    } catch (err) {
        console.error('Failed to connect to MSSQL:', err);
        process.exit(1);
    }
};

module.exports = { connectDB };
