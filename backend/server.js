const express = require('express');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const app = express();

// Enable CORS for frontend
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Accept']
}));

// Handle OPTIONS preflight
app.options('*', cors());

// Parse JSON body
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Ensure signed directory exists
const signedDir = path.join(__dirname, 'signed');
if (!fs.existsSync(signedDir)) {
    fs.mkdirSync(signedDir, { recursive: true });
}

// Configure multer for file uploads
const upload = multer({ 
    dest: '/tmp/',
    limits: { fileSize: 500 * 1024 * 1024 } // 500MB limit
});

// Log all requests
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - ${req.ip}`);
    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Serve signed files
app.use('/download', express.static(signedDir));

// Generate and serve plist for OTA installation
app.get('/install/:filename', (req, res) => {
    const filename = req.params.filename;
    const plistPath = path.join(signedDir, filename);
    
    if (!fs.existsSync(plistPath)) {
        return res.status(404).json({ error: 'Plist not found' });
    }
    
    res.setHeader('Content-Type', 'application/xml');
    res.setHeader('Content-Disposition', 'inline');
    fs.createReadStream(plistPath).pipe(res);
});

// OTA install link - redirects to itms-services
app.get('/ota/:filename', (req, res) => {
    const filename = req.params.filename;
    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const host = req.headers.host;
    const plistUrl = `${protocol}://${host}/install/${filename}`;
    const itmsUrl = `itms-services://?action=download-manifest&url=${encodeURIComponent(plistUrl)}`;
    
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Install App</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body { font-family: -apple-system, sans-serif; text-align: center; padding: 50px; }
                a { display: inline-block; background: #007AFF; color: white; padding: 15px 30px; 
                    text-decoration: none; border-radius: 8px; font-size: 18px; margin: 20px; }
            </style>
        </head>
        <body>
            <h1>Install Application</h1>
            <p>Tap the button below to install the app on your iOS device</p>
            <a href="${itmsUrl}">Install App</a>
            <p style="color: #666; font-size: 14px; margin-top: 30px;">
                Note: You must trust the developer in Settings > General > VPN & Device Management after installation.
            </p>
        </body>
        </html>
    `);
});

// Sign endpoint with file uploads
app.post('/sign', upload.fields([
    { name: 'ipa', maxCount: 1 },
    { name: 'cert', maxCount: 1 },
    { name: 'provision', maxCount: 1 }
]), (req, res) => {
    try {
        console.log('Signing request received');
        
        if (!req.files || !req.files.ipa || !req.files.cert || !req.files.provision) {
            return res.status(400).json({
                success: false,
                error: 'Missing required files: ipa, cert, or provision'
            });
        }

        const password = req.body.password || '';
        const ipaFile = req.files.ipa[0];
        const certFile = req.files.cert[0];
        const provFile = req.files.provision[0];

        console.log('Files received:', {
            ipa: ipaFile.originalname,
            cert: certFile.originalname,
            provision: provFile.originalname
        });

        const timestamp = Date.now();
        const baseName = path.basename(ipaFile.originalname, '.ipa');
        const outputFile = path.join(signedDir, `${baseName}_signed_${timestamp}.ipa`);
        const plistFile = path.join(signedDir, `${baseName}_${timestamp}.plist`);

        // Build zsign command arguments
        const zsignArgs = [
            '-k', certFile.path,
            '-m', provFile.path,
            '-p', password,
            '-o', outputFile,
            '-z', '9',
            ipaFile.path
        ];

        console.log('Running zsign with args:', zsignArgs);

        // Call zsign binary
        const zsignProcess = spawn('./src/zsign', zsignArgs, { cwd: __dirname });

        let output = '';
        let errorOutput = '';

        zsignProcess.stdout.on('data', (data) => {
            output += data.toString();
        });

        zsignProcess.stderr.on('data', (data) => {
            errorOutput += data.toString();
        });

        zsignProcess.on('close', (code) => {
            // Cleanup temp files
            try {
                fs.unlinkSync(ipaFile.path);
                fs.unlinkSync(certFile.path);
                fs.unlinkSync(provFile.path);
            } catch (e) {
                console.error('Failed to cleanup temp files:', e);
            }

            if (code !== 0) {
                console.error('zsign failed:', errorOutput);
                return res.status(500).json({
                    success: false,
                    error: `Signing failed: ${errorOutput || output}`
                });
            }

            if (!fs.existsSync(outputFile)) {
                return res.status(500).json({
                    success: false,
                    error: 'Output IPA file not created'
                });
            }

            // Generate plist for OTA
            const protocol = req.headers['x-forwarded-proto'] || req.protocol;
            const host = req.headers.host;
            const downloadUrl = `${protocol}://${host}/download/${path.basename(outputFile)}`;
            const installUrl = `${protocol}://${host}/install/${path.basename(plistFile)}`;
            const otaUrl = `${protocol}://${host}/ota/${path.basename(plistFile)}`;

            const plistContent = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>items</key>
    <array>
        <dict>
            <key>assets</key>
            <array>
                <dict>
                    <key>kind</key>
                    <string>software-package</string>
                    <key>url</key>
                    <string>${downloadUrl}</string>
                </dict>
            </array>
            <key>metadata</key>
            <dict>
                <key>bundle-identifier</key>
                <string>com.${baseName}.app</string>
                <key>bundle-version</key>
                <string>1.0</string>
                <key>kind</key>
                <string>software</string>
                <key>title</key>
                <string>${baseName}</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>`;

            fs.writeFileSync(plistFile, plistContent);

            // Return success with download/install URLs
            res.json({
                success: true,
                message: 'IPA signed successfully',
                downloadUrl: downloadUrl,
                installUrl: installUrl,
                otaUrl: otaUrl,
                fileName: path.basename(outputFile),
                bundleId: `com.${baseName}.app`,
                appName: baseName
            });
        });

    } catch (error) {
        console.error('Signing error:', error);
        res.status(500).json({
            success: false,
            error: error.message || 'Internal server error'
        });
    }
});

// Simple test endpoint
app.get('/sign', (req, res) => {
    res.json({ 
        message: 'Use POST /sign with multipart/form-data to sign IPA files',
        requiredFields: ['ipa', 'cert', 'provision'],
        optionalFields: ['password']
    });
});

app.listen(3000, () => {
    console.log('Server running on port 3000');
    console.log('Signed files directory:', signedDir);
});
