const axios = require('axios');
const sql = require('mssql');
const { getAuthToken, getWalletData } = require('./receiveConnection'); // Import functions from receiveConnection.js

async function receiveOffer(req) {
    try {
        // Extract the attributes and holder details from the request body
        const { holder, attributes } = req.body; // Include holder to fetch wallet data

        // Step 1: Get wallet data for the user
        const walletData = await getWalletData(holder);
        if (!walletData) {
            throw new Error(`Wallet not found for holder: ${holder}`);
        }

        // Step 2: Get JWT token for the user's wallet
        const jwtToken = await getAuthToken(walletData.wallet_id);
        
        // Fetch all credential offers from the ACA-Py agent (holder's side)
        const recordsResponse = await axios.get(
            `http://localhost:7011/issue-credential-2.0/records`,
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`,  // Use the retrieved JWT token
                    'Content-Type': 'application/json'
                }
            }
        );

        const records = recordsResponse.data.results; // Fetch the list of credential exchange records
        console.log("Fetched records: ", records);

        // Filter for the credential offer that matches the provided attributes
        const matchingOffer = records.find(record => {
            return record.credential_offer_dict &&
                record.credential_offer_dict.credential_preview.attributes.some(attr => 
                    attributes.some(reqAttr => 
                        attr.name === reqAttr.name && attr.value === reqAttr.value
                    )
                );
        });

        if (matchingOffer) {
            console.log('Matching offer found:', matchingOffer);

            const credExId = matchingOffer.cred_ex_id; // Get the credential exchange ID

            // Step 1: Accept the offer
            const acceptResponse = await axios.post(
                `http://localhost:7011/issue-credential-2.0/records/${credExId}/send-request`,
                {},
                {
                    headers: {
                        Authorization: `Bearer ${jwtToken}`,  // Use the retrieved JWT token
                        'Content-Type': 'application/json'
                    }
                }
            );

            console.log('Offer accepted:', acceptResponse.data);

            // Step 2: Store the credential
            const storeResponse = await axios.post(
                `http://localhost:7011/issue-credential-2.0/records/${credExId}/store`,
                {},
                {
                    headers: {
                        Authorization: `Bearer ${jwtToken}`,  // Use the retrieved JWT token
                        'Content-Type': 'application/json'
                    }
                }
            );

            console.log('Credential stored:', storeResponse.data);
            await sendMessage(); // Send the message after storing the credential
        } else {
            console.log('No matching credential offer found');
        }

    } catch (error) {
        console.error('Error processing credential offer:', error.message);
    }
}

async function sendMessage() {
    try {
        // Example: Call the external Node.js project endpoint
        const response = await axios.post(
            'http://localhost:5000/router/storeSuccess',  // Replace with the actual URL of the other Node.js project
            {Offer : "Success"}
        );
        console.log('Message sent successfully:', response.data);
    } catch (error) {
        console.error('Error sending message:', error.message);
    }
}

module.exports = { receiveOffer };
