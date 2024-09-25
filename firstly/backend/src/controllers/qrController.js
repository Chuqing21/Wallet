const sql = require('mssql');
const crypto = require('crypto');
const QRCode = require('qrcode');
const dbConfigWallet = require('../config/dbConfigWallet');
sql.globalConnectionPool = false;

// Initialize SQL connection pool
let poolPromise = sql.connect(dbConfigWallet)
    .then(pool => {
        console.log('Connected to MSSQL');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });

// Generate QR Code and save in DB
module.exports.generateQRCode = async (req, res) => {
    const { userID, PerID, EduBacID, CerID, IntelID, WorkExpID } = req.body;
    console.log("\n\nPerID is : " + PerID + "\n\n\n");
    try {
        const pool = await poolPromise;

        const dataString = `PerID=${PerID};EduBacID=${EduBacID};CerID=${CerID};IntelID=${IntelID};WorkExpID=${WorkExpID}`;
        const timestamp = Date.now().toString();
        const dataToHash = `${userID}:${timestamp}:${dataString}`;
        const qrHash = crypto.createHash('sha256').update(dataToHash).digest('hex');

        const qrCodeBuffer = await QRCode.toBuffer(qrHash);

        const result = await pool.request()
            .input('userID', sql.Int, userID)
            .input('PerID', sql.VarChar, PerID)
            .input('EduBacIDs', sql.VarChar, EduBacID)
            .input('CerIDs', sql.VarChar, CerID)
            .input('IntelIDs', sql.VarChar, IntelID)
            .input('WorkExpIDs', sql.VarChar, WorkExpID)
            .input('QRHashCode', sql.VarChar, qrHash)
            .input('QRCodeImage', sql.VarBinary, qrCodeBuffer)
            .query(`
                INSERT INTO QRPermission 
                (userID, PerID, EduBacIDs, CerIDs, IntelIDs, WorkExpIDs, QRHashCode, ExpireDate, QRCodeImage) 
                OUTPUT INSERTED.QRCodeImage
                VALUES (@userID, @PerID, @EduBacIDs, @CerIDs, @IntelIDs, @WorkExpIDs, @QRHashCode, DATEADD(DAY, 30, GETDATE()), @QRCodeImage);
            `);

        const qrCodeImageBase64 = result.recordset[0].QRCodeImage.toString('base64');

        res.status(201).json({
            qrHash,
            qrCodeImage: qrCodeImageBase64
        });
    } catch (err) {
        console.error('QR Code Generation Error: ', err);
        res.status(500).send('Server error');
    }
};

// Function to format date to 'YYYY-MM-DD'
const formatDate = (datetime) => {
    if (!datetime) return null;
    const date = new Date(datetime);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
};

// Search QR Code by hash
module.exports.searchQRCode = async (req, res) => {
    const { qrHashCode } = req.body;

    try {
        const pool = await poolPromise;

        const qrPermissionResult = await pool.request()
            .input('qrHashCode', sql.NVarChar, qrHashCode)
            .query(`
                SELECT * 
                FROM QRPermission 
                WHERE QRHashCode = @qrHashCode
                AND ExpireDate > GETDATE();
            `);

        if (qrPermissionResult.recordset.length === 0) {
            return res.status(404).send('QR code not found or expired.');
        }

        const qrPermissionData = qrPermissionResult.recordset[0];

        const splitIds = (idString) => {
            if (!idString) return [];
            return idString.replace(/;$/, '').split(';').map(id => id.trim()).filter(id => id !== '');
        };

        const fetchRelatedData = async (table, column, ids) => {
            const results = [];
            for (let id of ids) {
                const query = `SELECT * FROM ${table} WHERE CAST(${column} AS NVARCHAR) = @id`;
                const result = await pool.request()
                    .input('id', sql.NVarChar, id)
                    .query(query);
                results.push(...result.recordset);
            }
            return results;
        };

        const education = await fetchRelatedData('Education', 'EduBacID', splitIds(qrPermissionData.EduBacIDs));
        const qualification = await fetchRelatedData('Qualification', 'QuaID', splitIds(qrPermissionData.CerIDs));
        const softSkill = await fetchRelatedData('Skills', 'IntelID', splitIds(qrPermissionData.IntelIDs));
        const workExperience = await fetchRelatedData('Work', 'WorkExpID', splitIds(qrPermissionData.WorkExpIDs));
        const profile = qrPermissionData.PerID ? await fetchRelatedData('Profile', 'PerID', splitIds(qrPermissionData.PerID)) : null;

        // Format dates
        education.forEach(edu => {
            edu.EduStartDate = formatDate(edu.EduStartDate);
            edu.EduEndDate = formatDate(edu.EduEndDate);
        });

        qualification.forEach(quali => {
            quali.CerAcquiredDate = formatDate(quali.CerAcquiredDate);
        });

        workExperience.forEach(work => {
            work.WorkStartDate = formatDate(work.WorkStartDate);
            work.WorkEndDate = formatDate(work.WorkEndDate);
        });

        const responseData = {
            profile: profile ? profile[0] : null,
            education,
            qualification,
            softSkill,
            workExperience,
        };

        res.status(200).json(responseData);
    } catch (err) {
        console.error('QR Code Search Error: ', err);
        res.status(500).send('Server error');
    }
};

// Fetch QR codes by userID
module.exports.fetchQRCodesByUserId = async (req, res) => {
    const { userID } = req.body;

    try {
        const pool = await poolPromise;
        console.log("UserID is: " + userID);
        const qrCodesResult = await pool.request()
            .input('userID', sql.Int, userID)
            .query(`
                SELECT QRPermissionID, QRHashCode, QRCodeImage, ExpireDate 
                FROM QRPermission 
                WHERE UserID = @userID AND ExpireDate > GETDATE()
            `);

        if (qrCodesResult.recordset.length === 0) {
            return res.status(404).send('No active QR codes found for this user.');
        }

        const qrCodes = qrCodesResult.recordset.map(record => ({
            qrId: record.QRPermissionID,  // Add the QRPermissionID here
            qrHashCode: record.QRHashCode,
            qrCodeImage: record.QRCodeImage.toString('base64'),
            expireDate: record.ExpireDate.toISOString() // Format date as ISO string
        }));

        res.status(200).json({ qrCodes });
    } catch (err) {
        console.error('Fetch QR Codes by UserID Error:', err);
        res.status(500).send('Server error');
    }
};

module.exports.deleteQRCode = async (req, res) => {
    const { qrID } = req.body; // This qrID refers to QRPermissionID in the table

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('qrID', sql.Int, qrID) // Use qrID as the QRPermissionID
            .query(`
                UPDATE QRPermission
                SET ExpireDate = DATEADD(DAY, -1, GETDATE()) -- Set expire date to past to mark as deleted
                WHERE QRPermissionID = @qrID -- Update this to use QRPermissionID
            `);

        if (result.rowsAffected[0] === 0) {
            return res.status(404).send('QR code not found');
        }

        res.status(200).send('QR code deleted');
    } catch (err) {
        console.error('Delete QR Code Error:', err);
        res.status(500).send('Server error');
    }
};


module.exports.fetchCVByQRCode = async (req, res) => {
    const { qrId } = req.body;
    console.log('qrId:', qrId);
    try {
        const pool = await poolPromise;

        const qrPermissionResult = await pool.request()
            .input('qrPermissionID', sql.Int, qrId) // Ensure qrId is treated as an integer
            .query(`
              SELECT * 
              FROM QRPermission 
              WHERE QRPermissionID = @qrPermissionID 
              AND ExpireDate > GETDATE();  
            `);
                console.log("searched");
        if (qrPermissionResult.recordset.length === 0) {
            return res.status(404).send('QR code not found or expired.');
        }

        const qrPermissionData = qrPermissionResult.recordset[0];
        console.log("got result");

        const splitIds = (idString) => {
            console.log("Split IDs");

            if (!idString) return [];
            return idString.replace(/;$/, '').split(';').map(id => id.trim()).filter(id => id !== '');
        };

        const fetchRelatedData = async (table, column, ids) => {
            console.log("Fetching Data from table " + table);

            const results = [];
            for (let id of ids) {
                const query = `SELECT * FROM ${table} WHERE CAST(${column} AS NVARCHAR) = @id`;
                const result = await pool.request()
                    .input('id', sql.NVarChar, id)
                    .query(query);
                results.push(...result.recordset);
            }
            return results;
        };

        const education = await fetchRelatedData('Education', 'EduBacID', splitIds(qrPermissionData.EduBacIDs));
        const qualification = await fetchRelatedData('Qualification', 'QuaID', splitIds(qrPermissionData.CerIDs));
        const softSkill = await fetchRelatedData('Skills', 'IntelID', splitIds(qrPermissionData.IntelIDs));
        const workExperience = await fetchRelatedData('Work', 'WorkExpID', splitIds(qrPermissionData.WorkExpIDs));
        const profile = qrPermissionData.PerID ? await fetchRelatedData('Profile', 'PerID', splitIds(qrPermissionData.PerID)) : null;

        // Format dates to 'YYYY-MM-DD'
        education.forEach(edu => {
            edu.EduStartDate = formatDate(edu.EduStartDate);
            edu.EduEndDate = formatDate(edu.EduEndDate);
        });

        qualification.forEach(quali => {
            quali.CerAcquiredDate = formatDate(quali.CerAcquiredDate);
        });

        workExperience.forEach(work => {
            work.WorkStartDate = formatDate(work.WorkStartDate);
            work.WorkEndDate = formatDate(work.WorkEndDate);
        });

        const responseData = {
            profile: profile ? profile[0] : null,
            education,
            qualification,
            softSkill,
            workExperience,
        };

        res.status(200).json(responseData);
    } catch (err) {
        console.error('QR Code Search Error: ', err);
        res.status(500).send('Server error');
    }
};
