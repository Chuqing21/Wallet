const sql = require('mssql');
const bcrypt = require('bcryptjs');
const dbConfig = require('../config/dbConfigWallet');
const { createWalletandDID } = require('./acapyRegister'); // Corrected import

let poolPromise = sql.connect(dbConfig)
    .then(pool => {
        console.log('Connected to MSSQL Wallet DB');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });

    const register = async (req, res) => {
        const { email, password } = req.body;
    
        try {
            const pool = await poolPromise;
            const userExists = await pool.request()
                .input('email', sql.NVarChar, email)
                .query('SELECT AccountID FROM [Account] WHERE Email = @email');
    
            if (userExists.recordset.length > 0) {
                return res.status(400).send('Email already in use');
            } else {
                const hashedPassword = await bcrypt.hash(password, 10);
                const accountInsertResult = await pool.request()
                    .input('email', sql.NVarChar, email)
                    .input('password', sql.NVarChar, hashedPassword)
                    .query('INSERT INTO Account (Email, Password) OUTPUT INSERTED.AccountID VALUES (@email, @password)');
    
                const user = accountInsertResult.recordset[0];
    
                // Create wallet and DID after successful registration
                const walletResponse = await createWalletandDID(req, res); // Call and wait for response
                
                // If wallet creation fails, you should handle the error
                if (walletResponse instanceof Error) {
                    return res.status(500).send(walletResponse.message);
                }
    
                res.status(201).json({ id: user.AccountID, walletResponse });
            }
        } catch (err) {
            console.error('Register Error: ', err);
            res.status(500).send('Server error');
        }
    };
    

const login = async (req, res) => {
    const { email, password } = req.body;

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('email', sql.NVarChar, email)
            .query('SELECT AccountID, Password FROM [Account] WHERE Email = @email');

        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            const isPasswordValid = await bcrypt.compare(password, user.Password);
            if (isPasswordValid) {
                res.status(200).json({ id: user.AccountID });
            } else {
                res.status(401).send('Invalid email or password');
            }
        } else {
            res.status(401).send('Invalid email or password');
        }
    } catch (err) {
        console.error('Login Error: ', err);
        res.status(500).send('Server error');
    }
};

const logout = async (req, res) => {
    res.status(200).send('Logout successful');
};

module.exports = { register, login, logout };
