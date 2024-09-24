const dbConfigSAINO = require('./dbConfigSAINO');
const sql = require('mssql');
let sainoPoolPromise = sql.connect(dbConfigSAINO)
    .then(pool => {
        console.log('Connected to MSSQL SAINO DB');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });


module.exports.saveCVSkill = async (req, res) => {


    const { accountID, newSkillEntries, existingSkillEntries } = req.body;


    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const sainoPool = await sainoPoolPromise;
        if (existingSkillEntries && existingSkillEntries.length > 0) {

            // Process existing skill entries (updates or deletes)
            for (const skill of existingSkillEntries) {
                const { SoftHighlight, SoftDescription, isPublic } = skill;

                if (isPublic === false) {
                    // Delete the existing skill if isPublic is unchecked (false)
                    await sainoPool.request()
                        .input('InteHighlight', sql.NVarChar, SoftHighlight)
                        .query(`
                            DELETE FROM Skills
                            WHERE InteHighlight = @InteHighlight
                        `);
                } else {
                    // Update the existing skill if isPublic is true
                    await sainoPool.request()
                        .input('InteHighlight', sql.NVarChar, SoftHighlight)
                        .input('InteDescription', sql.NVarChar, SoftDescription)
                        .input('UserID', sql.Int, accountID)
                        .query(`
        IF EXISTS (SELECT 1 FROM Skills WHERE InteHighlight = @InteHighlight)
        BEGIN
            -- Update the skill if it exists
            UPDATE Skills
            SET InteDescription = @InteDescription
            WHERE InteHighlight = @InteHighlight
        END
        ELSE
        BEGIN
            -- Insert the skill if it doesn't exist
            INSERT INTO Skills (UserID, InteHighlight, InteDescription)
                            VALUES (@UserID, @InteHighlight, @InteDescription)
        END
    `);

                }
            }
        }
        // Process new skill entries (inserts)
        if (newSkillEntries && newSkillEntries.length > 0) {
            for (const skill of newSkillEntries) {
                const { SoftHighlight, SoftDescription, isPublic } = skill;

                // Insert only if isPublic is true
                if (isPublic === true) {
                    await sainoPool.request()
                        .input('UserID', sql.Int, accountID)
                        .input('InteHighlight', sql.NVarChar, SoftHighlight)
                        .input('InteDescription', sql.NVarChar, SoftDescription)
                        .query(`
                            INSERT INTO Skills (UserID, InteHighlight, InteDescription)
                            VALUES (@UserID, @InteHighlight, @InteDescription)
                        `);
                }
            }
        }
        // Sending success response after all operations are complete
        res.status(200).send('Skills saved successfully');

    } catch (e) {
        console.error('Error saving skills:', e.message);
        res.status(500).send('Server error');
    }
};

// Delete CV Skill
module.exports.deleteCVSkill = async (req, res) => {
    const { InteHighlight } = req.body;

    // Validate input
    if (!InteHighlight) {
        return res.status(400).send('Title is required');
    }
    console.error("1:" + InteHighlight);
    try {
        const sainoPool = await sainoPoolPromise;

        // Check if the skill exists
        const existingSkill = await sainoPool.request()
            .input('InteHighlight', sql.NVarChar, InteHighlight)
            .query('SELECT COUNT(*) AS count FROM Skills WHERE InteHighlight = @InteHighlight');

        if (existingSkill.recordset[0].count === 0) {
            return res.status(404).send('Skill not found');
        }

        // Delete the skill from the database
        await sainoPool.request()
            .input('InteHighlight', sql.NVarChar, InteHighlight)
            .query('DELETE FROM Skills WHERE InteHighlight = @InteHighlight');

        res.status(200).send('Skill deleted successfully');
    } catch (error) {
        console.error('Error deleting skill:', error.message);
        res.status(500).send('Server error');
    }
};

module.exports.saveCVProfile = async (accountID, photo, name, age, email_address, mobile_number, address, description) => {
    try {
        const sainoPool = await sainoPoolPromise;

        await sainoPool.request()
            .input('UserID', sql.Int, accountID)
            .input('Photo', sql.NVarChar, photo)
            .input('Name', sql.NVarChar, name)
            .input('Age', sql.NVarChar, age)
            .input('Email_Address', sql.NVarChar, email_address)
            .input('Mobile_Number', sql.NVarChar, mobile_number)
            .input('Address', sql.NVarChar, address)
            .input('Description', sql.NVarChar, description)
            .query(`
                    IF EXISTS (SELECT 1 FROM Profile WHERE UserID = @UserID)
                    BEGIN
                        UPDATE Profile
                        SET Photo = @Photo, Name = @Name, Age = @Age, Email_Address = @Email_Address, 
                            Mobile_Number = @Mobile_Number, Address = @Address, Description = @Description
                        WHERE UserID = @UserID
                    END
                    ELSE
                    BEGIN
                        INSERT INTO Profile (UserID, Photo, Name, Age, Email_Address, Mobile_Number, Address, Description)
                        VALUES (@UserID, @Photo, @Name, @Age, @Email_Address, @Mobile_Number, @Address, @Description)
                    END
                `);
    } catch (error) {
        console.error('Error saving profile to SAINO:', error);
        throw new Error('Failed to save profile to SAINO.');
    }
};

module.exports.deleteCVWork = async (req, res) => {
    const { job_title, company_name } = req.body;

    // Validate input
    if (!job_title || !company_name) {
        return res.status(200).json({ message: 'Job title and company name are required' });
    }

    try {
        const pool = await sainoPoolPromise;

        // Check if the work experience entry exists based on job_title and company_name
        const existingWork = await pool.request()
            .input('WorkTitle', sql.NVarChar, job_title)
            .input('WorkCompany', sql.NVarChar, company_name)
            .query(`
                SELECT COUNT(*) AS count FROM Work
                WHERE WorkTitle = @WorkTitle AND WorkCompany = @WorkCompany
            `);

        if (existingWork.recordset[0].count > 0) {
            // Delete the work experience entry
            await pool.request()
                .input('WorkTitle', sql.NVarChar, job_title)
                .input('WorkCompany', sql.NVarChar, company_name)
                .query(`
                    DELETE FROM Work
                    WHERE WorkTitle = @WorkTitle AND WorkCompany = @WorkCompany
                `);

            res.status(200).json({ message: 'Work experience deleted successfully' });
        } else {
            res.status(404).json({ message: 'Work experience not found' });
        }
    } catch (error) {
        console.error('Error deleting work experience:', error.message);
        res.status(500).json({ message: 'Error deleting work experience' });
    }
};
module.exports.deleteCVEducation = async (req, res) => {
    const { level, field_of_study, institute_name } = req.body;

    try {
        const sainoPool = await sainoPoolPromise;

        // Check if the education entry exists
        const existingEducation = await sainoPool.request()
            .input('LevelEdu', sql.NVarChar, level)
            .input('FieldOfStudy', sql.NVarChar, field_of_study)
            .input('InstituteName', sql.NVarChar, institute_name)
            .query('SELECT COUNT(*) AS count FROM Education WHERE LevelEdu = @LevelEdu AND FieldOfStudy = @FieldOfStudy AND InstituteName = @InstituteName');

        if (existingEducation.recordset[0].count > 0) {
            // Delete the education entry
            await sainoPool.request()
                .input('LevelEdu', sql.NVarChar, level)
                .input('FieldOfStudy', sql.NVarChar, field_of_study)
                .input('InstituteName', sql.NVarChar, institute_name)
                .query('DELETE FROM Education WHERE LevelEdu = @LevelEdu AND FieldOfStudy = @FieldOfStudy AND InstituteName = @InstituteName');

            res.status(200).json({ message: 'Education entry deleted successfully' });
        } else {
            res.status(404).json({ message: 'Education entry not found' });
        }
    } catch (error) {
        console.error('Error deleting education entry:', error.message);
        res.status(500).json({ message: 'Error deleting education entry' });
    }
};





module.exports.saveCVWork = async (req, res) => {
    const { accountID, newWorkEntries, existingWorkEntries } = req.body;

    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }
    console.log("Inside");
    try {
        const pool = await sainoPoolPromise;

        // Process existing entries (check for update or delete)
        if (existingWorkEntries && existingWorkEntries.length > 0) {
            console.log("Inside existing");

            for (let entry of existingWorkEntries) {
                const {
                    job_title, company_name, industry,
                    country, state, city, description, start_date, end_date, isPublic
                } = entry;
                console.log("existing 1");

                if (isPublic == false) {
                    console.log("existing ispublic false");
                    // Delete the existing work entry based on job_title and company_name if isPublic is false
                    await pool.request()
                        .input('WorkTitle', sql.NVarChar, job_title)
                        .input('WorkCompany', sql.NVarChar, company_name)
                        .query(`
                            DELETE FROM Work
                            WHERE WorkTitle = @WorkTitle AND WorkCompany = @WorkCompany
                        `);
                } else if (isPublic == true) {
                    // Update the existing work entry if isPublic is true
                    console.log("existingIsPublic");
                    // Log the input parameters for debugging
                    console.log('Updating work record with the following details:');
                    console.log('WorkTitle:', job_title);
                    console.log('WorkCompany:', company_name);
                    console.log('WorkIndustry:', industry);
                    console.log('WorkCountry:', country);
                    console.log('WorkState:', state);
                    console.log('WorkCity:', city);
                    console.log('WorkDescription:', description);
                    console.log('WorkStartDate:', start_date);
                    console.log('WorkEndDate:', end_date);

                    try {
                        const result = await pool.request()
                            .input('WorkTitle', sql.NVarChar, job_title)
                            .input('WorkCompany', sql.NVarChar, company_name)
                            .input('WorkIndustry', sql.NVarChar, industry)
                            .input('WorkCountry', sql.NVarChar, country)
                            .input('WorkState', sql.NVarChar, state)
                            .input('WorkCity', sql.NVarChar, city)
                            .input('WorkDescription', sql.NVarChar, description)
                            .input('WorkStartDate', sql.NVarChar, start_date)
                            .input('WorkEndDate', sql.NVarChar, end_date)
                            .query(`
            UPDATE Work
            SET WorkIndustry = @WorkIndustry, WorkCountry = @WorkCountry, WorkState = @WorkState,
                WorkCity = @WorkCity, WorkDescription = @WorkDescription, WorkStartDate = @WorkStartDate,
                WorkEndDate = @WorkEndDate
            WHERE WorkTitle = @WorkTitle AND WorkCompany = @WorkCompany
        `);

                        // Log the result of the query
                        console.log('Update successful:', result);
                    } catch (error) {
                        // Log any error that occurs during the query
                        console.error('Error updating work record:', error);
                    }

                }
            }
        }

        // Process new entries (inserts) only if isPublic is true
        if (newWorkEntries && newWorkEntries.length > 0) {
            console.log("Inside new");

            for (let entry of newWorkEntries) {
                const {
                    job_title, company_name, industry,
                    country, state, city, description, start_date, end_date, isPublic
                } = entry;

                // Only insert the new work entry if isPublic is true
                if (isPublic == true) {
                    console.log("new ispublic true");

                    // Check if the entry already exists based on job_title and company_name
                    const result = await pool.request()
                        .input('WorkTitle', sql.NVarChar, job_title)
                        .input('WorkCompany', sql.NVarChar, company_name)
                        .query(`
                            SELECT COUNT(*) AS count FROM Work
                            WHERE WorkTitle = @WorkTitle AND WorkCompany = @WorkCompany
                        `);

                    const count = result.recordset[0].count;

                    if (count === 0) {
                        // Insert if the entry does not already exist
                        await pool.request()
                            .input('UserID', sql.Int, accountID)  // Map accountID to userID
                            .input('WorkTitle', sql.NVarChar, job_title)
                            .input('WorkCompany', sql.NVarChar, company_name)
                            .input('WorkIndustry', sql.NVarChar, industry)
                            .input('WorkCountry', sql.NVarChar, country)
                            .input('WorkState', sql.NVarChar, state)
                            .input('WorkCity', sql.NVarChar, city)
                            .input('WorkDescription', sql.NVarChar, description)
                            .input('WorkStartDate', sql.NVarChar, start_date)
                            .input('WorkEndDate', sql.NVarChar, end_date)
                            .query(`
                                INSERT INTO Work (UserID, WorkTitle, WorkCompany, WorkIndustry,WorkCountry, WorkState, WorkCity, WorkDescription, WorkStartDate, WorkEndDate)
                                VALUES (@UserID, @WorkTitle, @WorkCompany, @WorkIndustry,@WorkCountry, @WorkState, @WorkCity, @WorkDescription, @WorkStartDate, @WorkEndDate)
                            `);
                    }
                }
                // If isPublic is false and not existing, do nothing
            }
        }

        // Send success response
        res.status(200).send('Work entries processed successfully');
    } catch (error) {
        console.error('Error saving work info:', error);
        res.status(500).send('Failed to save work info');
    }
};



module.exports.saveCVQuali = async (req, res) => {
    const { accountID, qualifications } = req.body;

    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const pool = await sainoPoolPromise;

        for (const qual of qualifications) {
            const { quaTitle, quaIssuer, quaDescription, quaAcquiredDate, isPublic } = qual;

            // Check if the qualification already exists by description, issuer, and acquired date
            const existingQualification = await pool.request()
                .input('CerDescription', sql.NVarChar, quaDescription)
                .input('CerIssuer', sql.NVarChar, quaIssuer)
                .input('CerAcquiredDate', sql.DateTime, quaAcquiredDate)
                .query(`
                    SELECT CerID FROM Qualification
                    WHERE CerDescription = @CerDescription AND CerIssuer = @CerIssuer AND CerAcquiredDate = @CerAcquiredDate
                `);

            // If the qualification exists
            if (existingQualification.recordset.length > 0) {

                if (isPublic === false) {
                    // Delete the existing qualification if isPublic is false
                    await pool.request()
                        .input('CerDescription', sql.NVarChar, quaDescription)
                        .input('CerIssuer', sql.NVarChar, quaIssuer)
                        .input('CerAcquiredDate', sql.DateTime, quaAcquiredDate)
                        .query(`
                            DELETE FROM Qualification
                            WHERE CerDescription = @CerDescription AND CerIssuer = @CerIssuer AND CerAcquiredDate = @CerAcquiredDate
                        `);
                } else {
                    // Update the existing qualification if isPublic is true
                    await pool.request()
                        .input('CerTitle', sql.NVarChar, quaTitle)
                        .input('CerIssuer', sql.NVarChar, quaIssuer)
                        .input('CerDescription', sql.NVarChar, quaDescription)
                        .input('CerAcquiredDate', sql.DateTime, quaAcquiredDate)
                        .query(`
                            UPDATE Qualification
                            SET CerTitle = @CerTitle, CerIssuer = @CerIssuer, CerDescription = @CerDescription, CerAcquiredDate = @CerAcquiredDate
                            WHERE CerDescription = @CerDescription AND CerIssuer = @CerIssuer AND CerAcquiredDate = @CerAcquiredDate
                        `);
                }
            } else if (isPublic === true) {
                // Insert the new qualification if it doesn't exist and isPublic is true
                await pool.request()
                    .input('UserID', sql.Int, accountID)  // Map accountID to UserID
                    .input('CerTitle', sql.NVarChar, quaTitle)
                    .input('CerIssuer', sql.NVarChar, quaIssuer)
                    .input('CerDescription', sql.NVarChar, quaDescription)
                    .input('CerAcquiredDate', sql.DateTime, quaAcquiredDate)
                    .query(`
                        INSERT INTO Qualification (UserID, CerTitle, CerIssuer, CerDescription, CerAcquiredDate)
                        OUTPUT INSERTED.CerID
                        VALUES (@UserID, @CerTitle, @CerIssuer, @CerDescription, @CerAcquiredDate)
                    `);
            }
        }

        // Send success response
        res.status(200).send('Qualification data processed successfully');
    } catch (error) {
        console.error('Error processing qualification data:', error);
        res.status(500).send('Error occurred while processing qualification data');
    }
};



module.exports.saveCVEducation = async (req, res) => {
    const { accountID, newEducationEntries, existingEducationEntries } = req.body;

    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const sainoPool = await sainoPoolPromise;

        // Process existing education entries (updates or deletes)
        if (existingEducationEntries && existingEducationEntries.length > 0) {
            for (const entry of existingEducationEntries) {
                const {
                    eduBacID, level, field_of_study, institute_name, institute_country, institute_city, institute_state, start_date, end_date, isPublic
                } = entry;

                if (isPublic == false) {
                    // Delete the existing education entry if isPublic is unchecked (false)
                    await sainoPool.request()
                        .input('LevelEdu', sql.NVarChar, level)
                        .input('FieldOfStudy', sql.NVarChar, field_of_study)
                        .input('InstituteName', sql.NVarChar, institute_name)
                        .query(`
                            DELETE FROM Education
                            WHERE LevelEdu = @LevelEdu AND FieldOfStudy = @FieldOfStudy AND InstituteName = @InstituteName
                        `);
                } else {
                    // Update the existing education entry if isPublic is true (note: we are not saving isPublic in the DB)
                    await sainoPool.request()
                        .input('UserID', sql.Int, accountID) // Assuming accountID is UserID
                        .input('LevelEdu', sql.NVarChar, level)
                        .input('FieldOfStudy', sql.NVarChar, field_of_study)
                        .input('InstituteName', sql.NVarChar, institute_name)
                        .input('InstituteCountry', sql.NVarChar, institute_country)
                        .input('InstituteCity', sql.NVarChar, institute_city)
                        .input('InstituteState', sql.NVarChar, institute_state)
                        .input('EduStartDate', sql.NVarChar, start_date)
                        .input('EduEndDate', sql.NVarChar, end_date)
                        .query(`
                        IF EXISTS (
                            SELECT 1 FROM Education 
                            WHERE LevelEdu = @LevelEdu AND FieldOfStudy = @FieldOfStudy AND InstituteName = @InstituteName
                        )
                        BEGIN
                            -- Update the education entry if it exists
                            UPDATE Education
                            SET InstituteCountry = @InstituteCountry, InstituteCity = @InstituteCity, InstituteState = @InstituteState, 
                                EduStartDate = @EduStartDate, EduEndDate = @EduEndDate
                            WHERE LevelEdu = @LevelEdu AND FieldOfStudy = @FieldOfStudy AND InstituteName = @InstituteName
                        END
                        ELSE
                        BEGIN
                            -- Insert the education entry if it doesn't exist
                            INSERT INTO Education (UserID, LevelEdu, FieldOfStudy, InstituteName, InstituteCountry, 
                                                   InstituteCity, InstituteState, EduStartDate, EduEndDate)
                            VALUES (@UserID, @LevelEdu, @FieldOfStudy, @InstituteName, @InstituteCountry, 
                                    @InstituteCity, @InstituteState, @EduStartDate, @EduEndDate)
                        END
                    `);

                }
            }
        }

        // Process new education entries (inserts) only if isPublic is true
        if (newEducationEntries && newEducationEntries.length > 0) {
            for (const entry of newEducationEntries) {
                const {
                    level, field_of_study, institute_name, institute_country, institute_city, institute_state, start_date, end_date, isPublic
                } = entry;

                // Insert new education entries only if isPublic is true
                if (isPublic == true) {
                    await sainoPool.request()
                        .input('UserID', sql.Int, accountID)
                        .input('LevelEdu', sql.NVarChar, level)
                        .input('FieldOfStudy', sql.NVarChar, field_of_study)
                        .input('InstituteName', sql.NVarChar, institute_name)
                        .input('InstituteCountry', sql.NVarChar, institute_country)
                        .input('InstituteCity', sql.NVarChar, institute_city)
                        .input('InstituteState', sql.NVarChar, institute_state)
                        .input('EduStartDate', sql.NVarChar, start_date)
                        .input('EduEndDate', sql.NVarChar, end_date)
                        .query(`
                            INSERT INTO Education (UserID, LevelEdu, FieldOfStudy, InstituteName, InstituteCountry, 
                                InstituteCity, InstituteState, EduStartDate, EduEndDate)
                            VALUES (@UserID, @LevelEdu, @FieldOfStudy, @InstituteName, @InstituteCountry, 
                                @InstituteCity, @InstituteState, @EduStartDate, @EduEndDate)
                        `);
                }
            }
        }

        // Sending success response after all operations are complete
        res.status(200).send('Education entries processed successfully');

    } catch (error) {
        console.error('Error saving education info:', error.message);
        res.status(500).send('Failed to save education info');
    }
};



module.exports.deleteCVEducation = async (req, res) => {
    const { level, field_of_study, institute_name } = req.body;

    if (!level || !field_of_study || !institute_name) {
        return res.status(200).json({ message: 'Level, field of study, and institute name are required' });
    }

    try {
        const pool = await sainoPoolPromise;

        // Check if the education entry exists based on the given fields
        const existingEducation = await pool.request()
            .input('LevelEdu', sql.NVarChar, level)
            .input('FieldOfStudy', sql.NVarChar, field_of_study)
            .input('InstituteName', sql.NVarChar, institute_name)
            .query(`
                SELECT COUNT(*) AS count FROM Education
                WHERE LevelEdu = @LevelEdu AND FieldOfStudy = @FieldOfStudy AND InstituteName = @InstituteName
            `);

        if (existingEducation.recordset[0].count > 0) {
            // Delete the education entry based on the given fields
            await pool.request()
                .input('LevelEdu', sql.NVarChar, level)
                .input('FieldOfStudy', sql.NVarChar, field_of_study)
                .input('InstituteName', sql.NVarChar, institute_name)
                .query(`
                    DELETE FROM Education
                    WHERE LevelEdu = @LevelEdu AND FieldOfStudy = @FieldOfStudy AND InstituteName = @InstituteName
                `);

            res.status(200).json({ message: 'Education entry deleted successfully' });
        } else {
            res.status(404).json({ message: 'Education entry not found' });
        }
    } catch (error) {
        console.error('Error deleting education entry:', error.message);
        res.status(500).json({ message: 'Error deleting education entry' });
    }
};

module.exports.deleteCVQualification = async (req, res) => {
    const { quaDescription, quaIssuer, quaAcquiredDate } = req.body;

    if (!quaDescription || !quaIssuer || !quaAcquiredDate) {
        return res.status(400).json({ message: 'Description, Issuer, and Acquired Date are required' });
    }

    try {
        const pool = await sainoPoolPromise;

        // Check if the qualification entry exists based on description, issuer, and acquired date
        const existingQualification = await pool.request()
            .input('QuaDescription', sql.NVarChar, quaDescription)
            .input('QuaIssuer', sql.NVarChar, quaIssuer)
            .input('QuaAcquiredDate', sql.DateTime, quaAcquiredDate)
            .query(`
                SELECT COUNT(*) AS count FROM Qualification
                WHERE QuaDescription = @QuaDescription AND QuaIssuer = @QuaIssuer AND QuaAcquiredDate = @QuaAcquiredDate
            `);

        if (existingQualification.recordset[0].count > 0) {
            // Delete the qualification entry
            await pool.request()
                .input('QuaDescription', sql.NVarChar, quaDescription)
                .input('QuaIssuer', sql.NVarChar, quaIssuer)
                .input('QuaAcquiredDate', sql.DateTime, quaAcquiredDate)
                .query(`
                    DELETE FROM Qualification
                    WHERE QuaDescription = @QuaDescription AND QuaIssuer = @QuaIssuer AND QuaAcquiredDate = @QuaAcquiredDate
                `);

            res.status(200).json({ message: 'Qualification deleted successfully' });
        } else {
            res.status(404).json({ message: 'Qualification not found' });
        }
    } catch (error) {
        console.error('Error deleting qualification:', error.message);
        res.status(500).json({ message: 'Error deleting qualification' });
    }
};