const sql = require('mssql');
sql.globalConnectionPool = false;
const dbConfigWallet = require('../config/dbConfigWallet');

// Initialize SQL connection pool
let poolPromise = new sql.connect(dbConfigWallet)
    .then(pool => {
        console.log('Connected to MSSQL Wallet DB');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });

// Update CV Status
module.exports.updateHasCV = async (req, res) => {
    const { accountID } = req.body;

    try {
        const result = await sql.query`
            UPDATE Account
            SET hasCV = 1, UpdatedAt = GETDATE()
            WHERE AccountID = ${accountID}`;

        if (result.rowsAffected[0] > 0) {
            res.status(200).send("hasCV updated successfully.");
        } else {
            res.status(404).send("Account not found.");
        }
    } catch (error) {
        console.error("Error updating hasCV:", error);
        res.status(500).send("An error occurred while updating hasCV.");
    }
};

// Check if CV exists
module.exports.checkCV = async (req, res) => {
    const accountID = req.query.accountID;
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query('SELECT hasCV FROM Account WHERE AccountID = @accountID');

        if (result.recordset.length > 0) {
            const { hasCV } = result.recordset[0];
            res.json({ hasCV });
        } else {
            res.status(404).send('Account not found');
        }
    } catch (err) {
        console.error('Error checking CV status:', err.message);
        res.status(500).send('Server error: ' + err.message);
    }
};


// ACCOUNT MANAGEMENT
module.exports.saveProfile = async (req, res) => {
    const { accountID, firstName, lastName, mobilePhone, email, icNumber, Photo } = req.body;
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }
    try {
        const pool = await poolPromise;
        // Check if the profile already exists
        const checkQuery = `
            SELECT COUNT(*) AS count FROM Person WHERE AccountID = @accountID`;
        const checkResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(checkQuery);
        const recordExists = checkResult.recordset[0].count > 0;

        let query;
        let binaryPhoto = null;

        if (recordExists) {
            // Update the existing record
            query = `
                UPDATE Person 
                SET First_Name = @firstName, 
                    Last_Name = @lastName, 
                    Mobile_Number = @mobilePhone, 
                    Email_Address = @email, 
                    Identity_Code = @icNumber`;
            if (Photo) {
                binaryPhoto = Buffer.from(Photo, 'base64'); // Decode base64 to binary
                query += `, Photo = @Photo`;
            }
            query += ` WHERE AccountID = @accountID`;
        } else {
            // Insert a new record
            query = `
                INSERT INTO Person (AccountID, First_Name, Last_Name, Mobile_Number, Email_Address, Identity_Code, Photo)
                VALUES (@accountID, @firstName, @lastName, @mobilePhone, @email, @icNumber, @Photo)`;
            if (Photo) {
                binaryPhoto = Buffer.from(Photo, 'base64'); // Decode base64 to binary
            }
        }

        // Prepare the request with inputs
        const request = pool.request()
            .input('accountID', sql.Int, accountID)
            .input('firstName', sql.NVarChar, firstName)
            .input('lastName', sql.NVarChar, lastName)
            .input('mobilePhone', sql.NVarChar, mobilePhone)
            .input('email', sql.NVarChar, email)
            .input('icNumber', sql.NVarChar, icNumber);
        if (binaryPhoto) {
            request.input('Photo', sql.VarBinary, binaryPhoto);
        } else {
            request.input('Photo', sql.VarBinary, null);  // Set photo as null if not provided
        }

        // Execute the query
        await request.query(query);
        const action = recordExists ? 'Profile updated successfully' : 'Profile created successfully';
        res.status(200).send(action);
    } catch (err) {
        console.error('Error saving profile:', err.message);
        res.status(500).send('Server error: ' + err.message);
    }
};

// Get User Profile
module.exports.getProfile = async (req, res) => {
    const accountID = req.query.accountID;
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query('SELECT First_Name, Last_Name, Mobile_Number, Email_Address, Identity_Code, Photo FROM Person WHERE AccountID = @accountID');
        if (result.recordset.length > 0) {
            const profile = result.recordset[0];
            // Convert photo binary data to base64 string
            if (profile.Photo) {
                profile.Photo = Buffer.from(profile.Photo).toString('base64');
            }
            res.json(profile);
        } else {
            res.status(404).send('Profile not found');
        }
    } catch (err) {
        console.error('Error fetching profile data:', err.message);
        res.status(500).send('Server error: ' + err.message);
    }
};

// Get Account Email
module.exports.getAccountEmail = async (req, res) => {
    const accountID = req.query.accountID;

    if (!accountID) {
        return res.status(400).json({ error: 'Account ID is required' });
    }

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query('SELECT Email FROM Account WHERE AccountID = @accountID');

        if (result.recordset.length > 0) {
            res.status(200).json({ Email: result.recordset[0].Email });
        } else {
            res.status(404).json({ error: 'Email not found for the given account ID' });
        }
    } catch (err) {
        console.error('Database query error:', err.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};


// CV MANAGEMENT
// CV Profile
// Save CV Profile
module.exports.saveCVProfile = async (req, res) => {
    const {
        accountID, photo, name, age, email_address, mobile_number, address, description
    } = req.body;

    try {
        // Fetch the connection pool
        const pool = await poolPromise;

        // Check if profile exists in the Profile table
        const existingProfile = await pool.request()
            .input('AccountID', sql.Int, accountID)
            .query('SELECT COUNT(*) AS count FROM Profile WHERE AccountID = @AccountID');

        // Update or insert into the Profile table
        if (existingProfile.recordset[0].count > 0) {
            await pool.request()
                .input('AccountID', sql.Int, accountID)
                .input('Photo', sql.NVarChar, photo)
                .input('Name', sql.NVarChar, name)
                .input('Age', sql.NVarChar, age)
                .input('Email_Address', sql.NVarChar, email_address)
                .input('Mobile_Number', sql.NVarChar, mobile_number)
                .input('Address', sql.NVarChar, address)
                .input('Description', sql.NVarChar, description)
                .query(`
                    UPDATE Profile
                    SET Photo = @Photo, Name = @Name, Age = @Age, Email_Address = @Email_Address, 
                        Mobile_Number = @Mobile_Number, Address = @Address, Description = @Description
                    WHERE AccountID = @AccountID
                `);
        } else {
            await pool.request()
                .input('AccountID', sql.Int, accountID)
                .input('Photo', sql.NVarChar, photo)
                .input('Name', sql.NVarChar, name)
                .input('Age', sql.Int, age)
                .input('Email_Address', sql.NVarChar, email_address)
                .input('Mobile_Number', sql.NVarChar, mobile_number)
                .input('Address', sql.NVarChar, address)
                .input('Description', sql.NVarChar, description)
                .query(`
                    INSERT INTO Profile (
                        AccountID, Photo, Name, Age, Email_Address, Mobile_Number, Address, Description
                    ) VALUES (
                        @AccountID, @Photo, @Name, @Age, @Email_Address, @Mobile_Number, @Address, @Description
                    )
                `);
        }


        res.status(200).send('Profile saved successfully');
    } catch (error) {
        console.error('Error saving profile:', error);
        res.status(500).send('Failed to save profile');
    }
};

// Get CV Profile 
module.exports.getCVProfile = async (req, res) => {
    const accountID = req.query.accountID;
    console.log('Received AccountID:', accountID);
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT Name AS name, Age AS age, Email_Address AS email, Mobile_Number AS phone, 
                    Address AS address, Description AS description, Photo AS profile_image_path 
                FROM Profile 
                WHERE AccountID = @accountID`);
        console.log('Query Result:', result.recordset);
        if (result.recordset.length === 0) {
            res.status(404).send('No profile data found');
        } else {
            res.json(result.recordset);
        }
    } catch (err) {
        console.error('Server error:', err);
        res.status(500).send('Server error');
    }
};

// Get Default Person Info : Name, Email, Phone
module.exports.getPersonDetails = async (req, res) => {
    const accountID = req.query.accountID;

    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const pool = await poolPromise;

        // SQL query to get email, full name, and mobile number
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT 
                    Email_Address AS Email, 
                    Last_Name + ' ' + First_Name AS FullName, 
                    Mobile_Number 
                FROM 
                    Person 
                WHERE 
                    AccountID = @accountID
            `);

        if (result.recordset.length > 0) {
            res.status(200).json(result.recordset[0]); // Return the first matching record
        } else {
            res.status(404).send('Person not found');
        }
    } catch (error) {
        console.error('Error fetching person details:', error);
        res.status(500).send('Failed to fetch person details');
    }
};


// CV Education
//Save CV Education
module.exports.saveCVEducation = async (req, res) => {
    const { accountID, newEducationEntries, existingEducationEntries } = req.body;

    try {
        const pool = await poolPromise;
        let newEducationsWithID = []; // Array to store newly inserted education entries with their EduBacID

        // Process existing entries (updates)
        if (existingEducationEntries && existingEducationEntries.length > 0) {
            for (let entry of existingEducationEntries) {
                const {
                    eduBacID, level, field_of_study, institute_name, institute_country, institute_city, institute_state, start_date, end_date, isPublic
                } = entry;

                await pool.request()
                    .input('EduBacID', sql.Int, eduBacID)
                    .input('LevelEdu', sql.NVarChar, level)
                    .input('FieldOfStudy', sql.NVarChar, field_of_study)
                    .input('InstituteName', sql.NVarChar, institute_name)
                    .input('InstituteCountry', sql.NVarChar, institute_country)
                    .input('InstituteCity', sql.NVarChar, institute_city)
                    .input('InstituteState', sql.NVarChar, institute_state)
                    .input('EduStartDate', sql.NVarChar, start_date)
                    .input('EduEndDate', sql.NVarChar, end_date)
                    .input('IsPublic', sql.Bit, isPublic)
                    .query(`
                        UPDATE Education
                        SET LevelEdu = @LevelEdu, FieldOfStudy = @FieldOfStudy, InstituteName = @InstituteName, 
                            InstituteCountry = @InstituteCountry, InstituteCity = @InstituteCity, 
                            InstituteState = @InstituteState, EduStartDate = @EduStartDate, EduEndDate = @EduEndDate,
                            IsPublic = @IsPublic
                        WHERE EduBacID = @EduBacID
                    `);
            }
        }

        // Process new entries (inserts)
        if (newEducationEntries && newEducationEntries.length > 0) {
            for (let entry of newEducationEntries) {
                const {
                    level, field_of_study, institute_name, institute_country, institute_city, institute_state, start_date, end_date, isPublic
                } = entry;

                // Capture the result of the insert query
                const result = await pool.request()
                    .input('AccountID', sql.Int, accountID)
                    .input('LevelEdu', sql.NVarChar, level)
                    .input('FieldOfStudy', sql.NVarChar, field_of_study)
                    .input('InstituteName', sql.NVarChar, institute_name)
                    .input('InstituteCountry', sql.NVarChar, institute_country)
                    .input('InstituteCity', sql.NVarChar, institute_city)
                    .input('InstituteState', sql.NVarChar, institute_state)
                    .input('EduStartDate', sql.NVarChar, start_date)
                    .input('EduEndDate', sql.NVarChar, end_date)
                    .input('IsPublic', sql.Bit, isPublic)
                    .query(`
                        INSERT INTO Education (AccountID, LevelEdu, FieldOfStudy, InstituteName, InstituteCountry, 
                            InstituteCity, InstituteState, EduStartDate, EduEndDate, IsPublic)
                        OUTPUT INSERTED.EduBacID
                        VALUES (@AccountID, @LevelEdu, @FieldOfStudy, @InstituteName, @InstituteCountry, 
                            @InstituteCity, @InstituteState, @EduStartDate, @EduEndDate, @IsPublic)
                    `);

                // Add the inserted EduBacID to the array
                if (result.recordset && result.recordset.length > 0) {
                    newEducationsWithID.push({
                        EduBacID: result.recordset[0].EduBacID,
                        level,
                        field_of_study,
                        institute_name
                    });
                } else {
                    console.error("Insert failed, no EduBacID returned.");
                }
            }
        }

        // Return success response with inserted IDs
        res.status(200).json({
            message: 'Education entries saved successfully',
            newEducationEntriesWithID: newEducationsWithID
        });
    } catch (error) {
        console.error('Error saving education info:', error);
        res.status(500).send('Failed to save education info');
    }
};

// Get CV Education
module.exports.getCVEducation = async (req, res) => {
    const accountID = req.query.accountID;
    console.log('Received AccountID:', accountID);

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT EduBacID AS eduBacID, LevelEdu AS level, FieldOfStudy AS field_of_study, 
                    InstituteName AS institute_name, InstituteCountry AS institute_country, 
                    InstituteState AS institute_state, InstituteCity AS institute_city, 
                    EduStartDate AS start_date, EduEndDate AS end_date, IsPublic AS isPublic
                FROM Education
                WHERE AccountID = @accountID
            `);

        console.log('Query Result:', result.recordset);

        if (result.recordset.length === 0) {
            res.status(404).send('No education data found');
        } else {
            res.json(result.recordset);
        }
    } catch (err) {
        console.error('Server error:', err);
        res.status(500).send('Server error');
    }
};

//Delete CV Education 
module.exports.deleteCVEducation = async (req, res) => {
    const { eduBacID } = req.body;

    try {
        const pool = await poolPromise;

        // Check if the education entry exists
        const existingEducation = await pool.request()
            .input('EduBacID', sql.Int, eduBacID)
            .query('SELECT COUNT(*) AS count FROM Education WHERE EduBacID = @EduBacID');

        if (existingEducation.recordset[0].count > 0) {
            // Delete the education entry
            await pool.request()
                .input('EduBacID', sql.Int, eduBacID)
                .query('DELETE FROM Education WHERE EduBacID = @EduBacID');

            res.status(200).json({ message: 'Education entry deleted successfully' });
        } else {
            res.status(404).json({ message: 'Education entry not found' });
        }
    } catch (error) {
        console.error('Error deleting education entry:', error.message);
        res.status(500).json({ message: 'Error deleting education entry' });
    }
};


// CV Work
// Save CV Work
module.exports.saveCVWork = async (req, res) => {
    const { accountID, newWorkEntries, existingWorkEntries } = req.body;

    try {
        const pool = await poolPromise;
        let newWorkWithID = []; // Array to store newly inserted work entries with their WorkExpID

        // Process existing work entries (updates)
        if (existingWorkEntries && existingWorkEntries.length > 0) {
            for (let entry of existingWorkEntries) {
                const {
                    workExpID, job_title, company_name, industry,
                    country, state, city, description, start_date, end_date, isPublic
                } = entry;

                await pool.request()
                    .input('WorkExpID', sql.Int, workExpID)
                    .input('WorkTitle', sql.NVarChar, job_title)
                    .input('WorkCompany', sql.NVarChar, company_name)
                    .input('WorkIndustry', sql.NVarChar, industry)
                    .input('WorkCountry', sql.NVarChar, country)
                    .input('WorkState', sql.NVarChar, state)
                    .input('WorkCity', sql.NVarChar, city)
                    .input('WorkDescription', sql.NVarChar, description)
                    .input('WorkStartDate', sql.NVarChar, start_date)
                    .input('WorkEndDate', sql.NVarChar, end_date)
                    .input('IsPublic', sql.Bit, isPublic)  // Including isPublic in the update
                    .query(`
                        UPDATE Work
                        SET WorkTitle = @WorkTitle, WorkCompany = @WorkCompany,
                            WorkIndustry = @WorkIndustry, WorkCountry = @WorkCountry, WorkState = @WorkState,
                            WorkCity = @WorkCity, WorkDescription = @WorkDescription, WorkStartDate = @WorkStartDate,
                            WorkEndDate = @WorkEndDate, IsPublic = @IsPublic
                        WHERE WorkExpID = @WorkExpID
                    `);
            }
        }

        // Process new work entries (inserts)
        if (newWorkEntries && newWorkEntries.length > 0) {
            for (let entry of newWorkEntries) {
                const {
                    job_title, company_name, industry,
                    country, state, city, description, start_date, end_date, isPublic
                } = entry;

                const result = await pool.request()
                    .input('AccountID', sql.Int, accountID)
                    .input('WorkTitle', sql.NVarChar, job_title)
                    .input('WorkCompany', sql.NVarChar, company_name)
                    .input('WorkIndustry', sql.NVarChar, industry)
                    .input('WorkCountry', sql.NVarChar, country)
                    .input('WorkState', sql.NVarChar, state)
                    .input('WorkCity', sql.NVarChar, city)
                    .input('WorkDescription', sql.NVarChar, description)
                    .input('WorkStartDate', sql.NVarChar, start_date)
                    .input('WorkEndDate', sql.NVarChar, end_date)
                    .input('IsPublic', sql.Bit, isPublic)  // Including isPublic in the insert
                    .query(`
                        INSERT INTO Work (AccountID, WorkTitle, WorkCompany, WorkIndustry, 
                                          WorkCountry, WorkState, WorkCity, WorkDescription, WorkStartDate, WorkEndDate, IsPublic)
                        OUTPUT INSERTED.WorkExpID
                        VALUES (@AccountID, @WorkTitle, @WorkCompany, @WorkIndustry, 
                                @WorkCountry, @WorkState, @WorkCity, @WorkDescription, @WorkStartDate, @WorkEndDate, @IsPublic)
                    `);

                newWorkWithID.push({
                    WorkExpID: result.recordset[0].WorkExpID,
                    job_title,
                    company_name
                });
            }
        }

        // Send success response
        res.status(200).json({
            message: 'Work entries processed successfully',
            newWorkWithID
        });
    } catch (error) {
        console.error('Error saving work info:', error);
        res.status(500).send('Failed to save work info');
    }
};

// Get CV Work 
module.exports.getCVWork = async (req, res) => {
    const accountID = req.query.accountID;
    console.log('Received AccountID:', accountID);

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT
                    WorkExpID AS workExpID, 
                    WorkTitle AS job_title, 
                    WorkCompany AS company_name, 
                    WorkIndustry AS industry, 
                    WorkCountry AS country, 
                    WorkState AS state, 
                    WorkCity AS city, 
                    WorkDescription AS description, 
                    WorkStartDate AS start_date, 
                    WorkEndDate AS end_date,
                    isPublic AS isPublic
                FROM Work
                WHERE AccountID = @accountID
            `);

        console.log('Query Result:', result.recordset);

        if (result.recordset.length === 0) {
            res.status(200).send('No work data found');
        } else {
            res.json(result.recordset);
        }
    } catch (err) {
        console.error('Server error:', err);
        res.status(500).send('Server error');
    }
};

// Delete CV Work
module.exports.deleteCVWork = async (req, res) => {
    const { workExpID } = req.body;

    try {
        const pool = await poolPromise;

        // Check if the work experience entry exists
        const existingWork = await pool.request()
            .input('WorkExpID', sql.Int, workExpID)
            .query('SELECT COUNT(*) AS count FROM Work WHERE WorkExpID = @WorkExpID');

        if (existingWork.recordset[0].count > 0) {
            // Delete the work experience entry
            await pool.request()
                .input('WorkExpID', sql.Int, workExpID)
                .query('DELETE FROM Work WHERE WorkExpID = @WorkExpID');

            res.status(200).json({ message: 'Work experience deleted successfully' });
        } else {
            res.status(404).json({ message: 'Work experience not found' });
        }
    } catch (error) {
        console.error('Error deleting work experience:', error.message);
        res.status(500).json({ message: 'Error deleting work experience' });
    }
};

// CV Skill
// Save CV Skill
module.exports.saveCVSkill = async (req, res) => {
    const { accountID, newSkillEntries, existingSkillEntries } = req.body;

    // Validate input
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const pool = await poolPromise;
        let newSkillsWithID = []; // Array to store newly inserted skills with their SoftID

        // Process existing skills (updates)
        if (existingSkillEntries && existingSkillEntries.length > 0) {
            for (const skill of existingSkillEntries) {
                const { SoftID, SoftHighlight, SoftDescription, isPublic } = skill;

                // Update the existing skill in the SoftSkill table
                await pool.request()
                    .input('SoftID', sql.Int, SoftID)
                    .input('SoftHighlight', sql.NVarChar, SoftHighlight)
                    .input('SoftDescription', sql.NVarChar, SoftDescription)
                    .input('IsPublic', sql.Bit, isPublic)
                    .query(`
                        UPDATE SoftSkill
                        SET SoftHighlight = @SoftHighlight, SoftDescription = @SoftDescription, IsPublic = @IsPublic
                        WHERE SoftID = @SoftID
                    `);
            }
        }

        // Process new skills (inserts)
        if (newSkillEntries && newSkillEntries.length > 0) {
            for (const skill of newSkillEntries) {
                const { SoftHighlight, SoftDescription, isPublic } = skill;

                // Insert new skill into the SoftSkill table
                const result = await pool.request()
                    .input('AccountID', sql.Int, accountID)
                    .input('SoftHighlight', sql.NVarChar, SoftHighlight)
                    .input('SoftDescription', sql.NVarChar, SoftDescription)
                    .input('IsPublic', sql.Bit, isPublic)
                    .query(`
                        INSERT INTO SoftSkill (AccountID, SoftHighlight, SoftDescription, IsPublic)
                        OUTPUT INSERTED.SoftID
                        VALUES (@AccountID, @SoftHighlight, @SoftDescription, @IsPublic)
                    `);

                // Add newly inserted SoftID to the response array
                newSkillsWithID.push({
                    SoftID: result.recordset[0].SoftID,
                    SoftHighlight,
                    SoftDescription
                });
            }
        }

        // Return the new skills with their IDs along with a success message
        res.status(200).json({
            message: 'Skills saved successfully',
            newSkillEntriesWithID: newSkillsWithID
        });
    } catch (error) {
        console.error('Error saving skills:', error.message);
        res.status(500).send('Server error');
    }
};

// Get CV Skill 
module.exports.getCVSkill = async (req, res) => {
    const accountID = req.query.accountID;
    console.log('Received AccountID:', accountID);

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('AccountID', sql.Int, accountID)
            .query(`
                SELECT 
                    SoftID AS SoftID,
                    SoftHighlight AS SoftHighlight,
                    SoftDescription AS SoftDescription,
                    isPublic AS isPublic
                FROM SoftSkill
                WHERE AccountID = @AccountID
            `);

        console.log('Query Result:', JSON.stringify(result.recordset, null, 2));

        if (result.recordset.length === 0) {
            res.status(404).send('No soft skill data found');
        } else {
            res.json(result.recordset);
        }
    } catch (err) {
        console.error('Server error:', err);
        res.status(500).send('Server error');
    }
};

// Delete CV Skill
module.exports.deleteCVSkill = async (req, res) => {
    const { SoftID } = req.body;

    // Validate input
    if (!SoftID) {
        return res.status(400).send('SoftID is required');
    }

    try {
        const pool = await poolPromise;

        // Check if the skill exists
        const existingSkill = await pool.request()
            .input('SoftID', sql.Int, SoftID)
            .query('SELECT COUNT(*) AS count FROM SoftSkill WHERE SoftID = @SoftID');

        if (existingSkill.recordset[0].count === 0) {
            return res.status(404).send('Skill not found');
        }

        // Delete the skill from the database
        await pool.request()
            .input('SoftID', sql.Int, SoftID)
            .query('DELETE FROM SoftSkill WHERE SoftID = @SoftID');

        res.status(200).send('Skill deleted successfully');
    } catch (error) {
        console.error('Error deleting skill:', error.message);
        res.status(500).send('Server error');
    }
};





// Get Certifications
module.exports.getCertifications = async (req, res) => {
    const accountID = req.query.accountID;
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT 
                  CerName AS [Name], 
                  CerEmail AS [Email], 
                  CerType AS [Certification Type], 
                  CerIssuer AS [Issuer], 
                  CerDescription AS [Description], 
                  CerAcquiredDate AS [Certification Acquire Date],
                  isPublic AS isPublic
                FROM 
                  Certification 
                WHERE 
                  AccountID = @accountID
            `);

        console.log(result.recordset); // Log the result for debugging purposes
        res.json({ certifications: result.recordset });
    } catch (error) {
        console.error('Error fetching certifications:', error);
        res.status(500).send('Internal Server Error');
    }
};

// Update Certification - Public
module.exports.updateCertificationStatus = async (req, res) => {
    const { accountID, certificationName, isPublic } = req.body;

    if (!accountID || !certificationName || typeof isPublic !== 'number') {
        return res.status(400).send('Missing required fields');
    }

    try {
        const pool = await poolPromise;
        await pool.request()
            .input('accountID', sql.Int, accountID)
            .input('certificationName', sql.VarChar, certificationName)
            .input('isPublic', sql.Int, isPublic)
            .query(`
              UPDATE Certification
              SET IsPublic = @isPublic
              WHERE AccountID = @accountID AND CerName = @certificationName
            `);

        res.status(200).send('Public status updated successfully');
    } catch (error) {
        console.error('Error updating public status:', error);
        res.status(500).send('Internal Server Error');
    }
};














// Fetch all certification types for a specific accountID
module.exports.getCertificationTypes = async (req, res) => {
    const accountID = req.query.accountID;
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT CerID, CerType
                FROM Certification
                WHERE AccountID = @accountID
            `);

        res.json({ certifications: result.recordset });
    } catch (error) {
        console.error('Error fetching certifications:', error);
        res.status(500).send('Internal Server Error');
    }
};



// Get Certification Types
module.exports.getCertificationTypes = async (req, res) => {
    const accountID = req.query.accountID;
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(`
                SELECT CerID, CerType
                FROM Certification
                WHERE AccountID = @accountID
            `);

        res.json({ certifications: result.recordset });
    } catch (error) {
        console.error('Error fetching certifications:', error);
        res.status(500).send('Internal Server Error');
    }
};

// Get Certification Details by CerID
module.exports.getCertificationDetails = async (req, res) => {
    const cerID = req.query.cerID;
    if (!cerID) {
        return res.status(400).send('CerID is required');
    }

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('cerID', sql.Int, cerID)
            .query(`
                SELECT CerName, CerEmail, CerIssuer, CerDescription, CerAcquiredDate
                FROM Certification
                WHERE CerID = @cerID
            `);

        res.json(result.recordset[0]); // Assuming only one record
    } catch (error) {
        console.error('Error fetching certification details:', error);
        res.status(500).send('Internal Server Error');
    }
};




// Save CV Qualification Info
module.exports.saveCVQuali = async (req, res) => {
    const { accountID, qualifications } = req.body;

    try {
        const pool = await poolPromise;
        let newQualificationsWithID = [];

        // Process existing qualifications (updates)
        if (qualifications && qualifications.length > 0) {
            for (const qual of qualifications) {
                const { quaID, quaTitle, quaIssuer, quaDescription, quaAcquiredDate, isPublic } = qual;

                if (quaID) {
                    await pool.request()
                        .input('QuaID', sql.Int, quaID)
                        .input('QuaTitle', sql.NVarChar, quaTitle)
                        .input('QuaIssuer', sql.NVarChar, quaIssuer)
                        .input('QuaDescription', sql.NVarChar, quaDescription)
                        .input('QuaAcquiredDate', sql.DateTime, quaAcquiredDate)
                        .input('IsPublic', sql.Bit, isPublic)
                        .query(`
                            UPDATE Qualification
                            SET QuaTitle = @QuaTitle, QuaIssuer = @QuaIssuer, 
                                QuaDescription = @QuaDescription, QuaAcquiredDate = @QuaAcquiredDate, IsPublic = @IsPublic
                            WHERE QuaID = @QuaID
                        `);
                } else {
                    const result = await pool.request()
                        .input('AccountID', sql.Int, accountID)
                        .input('QuaTitle', sql.NVarChar, quaTitle)
                        .input('QuaIssuer', sql.NVarChar, quaIssuer)
                        .input('QuaDescription', sql.NVarChar, quaDescription)
                        .input('QuaAcquiredDate', sql.DateTime, quaAcquiredDate)
                        .input('IsPublic', sql.Bit, isPublic)
                        .query(`
                            INSERT INTO Qualification (AccountID, QuaTitle, QuaIssuer, QuaDescription, QuaAcquiredDate, IsPublic)
                            OUTPUT INSERTED.QuaID
                            VALUES (@AccountID, @QuaTitle, @QuaIssuer, @QuaDescription, @QuaAcquiredDate, @IsPublic)
                        `);

                    newQualificationsWithID.push({
                        QuaID: result.recordset[0].QuaID,
                        quaTitle,
                        quaIssuer
                    });
                }
            }
        }

        res.status(200).json({
            message: 'Qualifications processed successfully',
            newQualificationsWithID
        });
    } catch (error) {
        console.error('Error saving qualification info:', error);
        res.status(500).send('Failed to save qualification info');
    }
};

// Get CV Qualification Info
module.exports.getCVQualiInfo = async (req, res) => {
    const accountID = req.query.accountID;

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('AccountID', sql.Int, accountID)
            .query(`
                SELECT QuaID AS qualification_id, QuaTitle AS title, QuaIssuer AS issuer,
                       QuaDescription AS description, QuaAcquiredDate AS acquired_date,
                       IsPublic AS isPublic
                FROM Qualification
                WHERE AccountID = @AccountID
            `);

        if (result.recordset.length === 0) {
            res.status(404).send('No qualification data found');
        } else {
            res.json(result.recordset);
        }
    } catch (err) {
        console.error('Server error:', err);
        res.status(500).send('Server error');
    }
};




module.exports.showDetails = async (req, res) => {
    try {
        const { accountID } = req.body; // Get accountID from the request body

        if (!accountID) {
            return res.status(400).json({ error: 'AccountID is required' });
        }

        const pool = await poolPromise;
        console.log("Start 1");
        // Fetch Profile information
        const profileQuery = `
            SELECT 
                Name AS name, 
                Age AS age, 
                Email_Address AS email, 
                Mobile_Number AS phone, 
                Address AS address, 
                Description AS description, 
                Photo AS profile_image_path
            FROM Profile
            WHERE AccountID = @accountID
        `;
        const profileResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(profileQuery);
        console.log("Start 2");

        if (profileResult.recordset.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        const userDetails = profileResult.recordset[0];

        // If the user has a photo, encode it in base64
        if (userDetails.profile_image_path) {
            userDetails.profile_image_path = Buffer.from(userDetails.profile_image_path).toString('base64');
        }

        // Fetch Education information
        const educationQuery = `
            SELECT 
                EduBacID AS eduBacID, 
                LevelEdu AS level, 
                FieldOfStudy AS field_of_study, 
                InstituteName AS institute_name, 
                InstituteCountry AS institute_country, 
                InstituteState AS institute_state, 
                InstituteCity AS institute_city, 
                CONVERT(VARCHAR(10), EduStartDate, 120) AS start_date, 
                CONVERT(VARCHAR(10), EduEndDate, 120) AS end_date, 
                IsPublic AS isPublic
            FROM Education 
            WHERE AccountID = @accountID AND IsPublic = 1
        `;
        const educationResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(educationQuery);
        console.log("Start 3");

        // Fetch Work Experience information
        const workExperienceQuery = `
            SELECT
                WorkExpID AS workExpID, 
                WorkTitle AS job_title, 
                WorkCompany AS company_name, 
                WorkIndustry AS industry, 
                WorkCountry AS country, 
                WorkState AS state, 
                WorkCity AS city, 
                WorkDescription AS description, 
                CONVERT(VARCHAR(10), WorkStartDate, 120) AS start_date, 
                CONVERT(VARCHAR(10), WorkEndDate, 120) AS end_date
            FROM Work
            WHERE AccountID = @accountID AND IsPublic = 1
        `;
        const workExperienceResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(workExperienceQuery);
        console.log("Start 4");

        // Fetch Skills information
        const skillsQuery = `
            SELECT 
                SoftID AS SoftID,
                SoftHighlight AS skill,
                SoftDescription AS description,
                IsPublic AS isPublic
            FROM SoftSkill
            WHERE AccountID = @accountID AND IsPublic = 1
        `;
        const skillsResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(skillsQuery);

        console.log("Start 5");


        const certificationsQuery = `
    SELECT 
        CerID AS cerID, 
        CerName AS name, 
        CerEmail AS email, 
        CerType AS type, 
        CerIssuer AS issuer, 
        CerDescription AS description, 
        CONVERT(VARCHAR(10), CerAcquiredDate, 120) AS acquiredDate,
        IsPublic AS isPublic
    FROM Certification 
    WHERE AccountID = @accountID AND IsPublic = 1
`;
        console.log("Start 6");



        const certificationResult = await pool.request()
            .input('accountID', sql.Int, accountID)
            .query(certificationsQuery);


        // Combine profile, education, work experience, and skills details into a single object
        const combinedDetails = {
            profile: userDetails,
            education: educationResult.recordset,
            workExperience: workExperienceResult.recordset,
            skills: skillsResult.recordset, // Add skills details here
            certification: certificationResult.recordset,
        };

        res.status(200).json(combinedDetails);
    } catch (err) {
        console.error('Show Details Error:', err);
        res.status(500).json({ error: 'Server error. Please try again later.' });
    }
};
