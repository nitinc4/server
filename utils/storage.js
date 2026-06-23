const fs = require('fs');
const path = require('path');

/**
 * Uploads a local file to AWS S3 if S3 is configured, or returns the local URL.
 * @param {string} localPath - The path to the local file.
 * @param {string} filename - The filename.
 * @param {string} mimetype - The mime type of the file.
 * @param {object} req - Express request object to resolve host.
 * @returns {Promise<string>} The resolved public URL of the file.
 */
async function getFileStorageUrl(localPath, filename, mimetype, req) {
  const s3Bucket = process.env.AWS_S3_BUCKET;
  const s3Region = process.env.AWS_REGION;
  const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
  const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;

  if (s3Bucket && accessKeyId && secretAccessKey) {
    try {
      // Dynamic import of aws-sdk to maintain resilience
      const AWS = require('aws-sdk');
      const s3 = new AWS.S3({
        accessKeyId,
        secretAccessKey,
        region: s3Region || 'us-east-1'
      });

      const fileContent = fs.readFileSync(localPath);
      const params = {
        Bucket: s3Bucket,
        Key: `uploads/${Date.now()}-${filename}`,
        Body: fileContent,
        ContentType: mimetype,
        ACL: 'public-read'
      };

      let uploadResult;
      try {
        uploadResult = await s3.upload(params).promise();
      } catch (uploadErr) {
        // Traps ACL blockages (AccessControlListNotSupported is returned when ACLs are disabled,
        // and AccessDenied is returned when Block Public Access settings prevent ACL uploads)
        if (
          uploadErr.code === 'AccessControlListNotSupported' ||
          uploadErr.message.includes('ACL') ||
          uploadErr.code === 'AccessDenied'
        ) {
          console.warn('[AWS S3] S3 Bucket blocks public ACLs (default for modern buckets). Retrying upload without ACL parameters...');
          const fallbackParams = {
            Bucket: s3Bucket,
            Key: `uploads/${Date.now()}-${filename}`,
            Body: fileContent,
            ContentType: mimetype
          };
          uploadResult = await s3.upload(fallbackParams).promise();
        } else {
          throw uploadErr;
        }
      }
      
      // Cleanup the temporary local file on disk
      try {
        fs.unlinkSync(localPath);
      } catch (unlinkErr) {
        console.error('[Storage Helper] Temporary file unlink failed:', unlinkErr.message);
      }

      console.log('[AWS S3] File successfully stored in cloud bucket:', uploadResult.Location);
      return uploadResult.Location;
    } catch (err) {
      console.error('[AWS S3] Upload failed, falling back to local URL:', err.message);
    }
  }

  // Fallback to dynamic host domain
  const domain = process.env.PRODUCTION_DOMAIN || `${req.protocol}://${req.get('host')}`;
  return `${domain}/uploads/${filename}`;
}

module.exports = {
  getFileStorageUrl
};
