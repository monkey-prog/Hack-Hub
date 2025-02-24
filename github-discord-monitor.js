// GitHub to Discord Webhook Integration
// This script can be used as a GitHub Action to send script.lua updates to Discord

const fs = require('fs');
const https = require('https');
const path = require('path');

// Configuration with your actual webhook URL
const DISCORD_WEBHOOK_URL = 'https://discord.com/api/webhooks/1343686063662825635/VVv1euDJPBGHCCvI_-J34eQ9NdoeeR8X-GuRX0ki1OB6B6xJYPj-4xTLKuK3C-IOoLXF';
const FILE_TO_MONITOR = 'script.lua';

// Function to send message to Discord
function sendToDiscord(content) {
  return new Promise((resolve, reject) => {
    // Parse the webhook URL
    const webhookUrl = new URL(DISCORD_WEBHOOK_URL);
    
    // Prepare the payload
    const payload = JSON.stringify({
      content: content,
      username: 'GitHub Script Monitor',
      avatar_url: 'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png'
    });
    
    // Prepare the request options
    const options = {
      hostname: webhookUrl.hostname,
      port: 443,
      path: webhookUrl.pathname + webhookUrl.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': payload.length
      }
    };
    
    // Send the request
    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log('Message sent successfully to Discord');
          resolve();
        } else {
          console.error(`Failed to send message: ${res.statusCode} ${data}`);
          reject(new Error(`HTTP Error: ${res.statusCode}`));
        }
      });
    });
    
    req.on('error', (error) => {
      console.error('Error sending message:', error);
      reject(error);
    });
    
    req.write(payload);
    req.end();
  });
}

// Function to read file content
function readFile(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

// Main function to process and send file
async function main() {
  try {
    // Get file path
    const filePath = path.join(process.cwd(), FILE_TO_MONITOR);
    
    // Check if file exists
    if (!fs.existsSync(filePath)) {
      console.error(`File ${FILE_TO_MONITOR} not found`);
      process.exit(1);
    }
    
    // Read file content
    const fileContent = readFile(filePath);
    
    // Format message
    const message = `**Updated ${FILE_TO_MONITOR}**\n\`\`\`lua\n${fileContent}\n\`\`\``;
    
    // Send to Discord
    await sendToDiscord(message);
    
    console.log('Process completed successfully');
  } catch (error) {
    console.error('Error in main process:', error);
    process.exit(1);
  }
}

// Run the main function
main();
