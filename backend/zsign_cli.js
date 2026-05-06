const { exec } = require('child_process');

function signIPA(ipaPath, cert, mobileProvision, callback) {
    const cmd = `./zsign -k ${cert} -m ${mobileProvision} -o output.ipa ${ipaPath}`;
    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            callback(`Error: ${error.message}`);
            return;
        }
        if (stderr) {
            callback(`stderr: ${stderr}`);
            return;
        }
        callback(`stdout: ${stdout}`);
    });
}

module.exports = signIPA;
