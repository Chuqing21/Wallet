const express = require('express');
const {
    saveCVProfile,
    saveCVSkill,
    deleteCVSkill,
    saveCVEducation,
    deleteCVEducation,
    saveCVWork,
    deleteCVWork,
    saveCVQuali,
    deleteCVQualification
} = require('./cvControllerSAINO'); // Import the controller functions

const router = express.Router();

// Route to save profile to SAINO DB
router.post('/saveCVProfile', saveCVProfile);

// Route to save skills to SAINO DB
router.post('/saveCVSkill', saveCVSkill);

// Route to delete a skill from SAINO DB
router.post('/deleteCVSkill', deleteCVSkill);

// Route to save education to SAINO DB
router.post('/saveCVEducation', saveCVEducation);

// Route to delete education from SAINO DB
router.post('/deleteCVEducation', deleteCVEducation);

// Route to save work experience to SAINO DB
router.post('/saveCVWork', saveCVWork);

// Route to delete work experience from SAINO DB
router.post('/deleteCVWork', deleteCVWork);

// Route to save qualifications to SAINO DB
router.post('/saveCVQuali', saveCVQuali);

// Route to delete a qualification from SAINO DB
router.post('/deleteCVQualification', deleteCVQualification);

module.exports = router;
