const dbConfig = {
    user: 'XH',
    password: 'System@123',
    server: '127.0.0.3',
    database: 'SAINO',
    options: {
        encrypt: true,
        trustServerCertificate: true,
        enableArithAbort: true,
        connectTimeout: 30000,
        requestTimeout: 30000,
    },
    port: 1433,
};

module.exports = dbConfig;
