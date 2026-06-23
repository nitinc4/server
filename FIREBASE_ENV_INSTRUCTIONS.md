# Firebase Cloud Messaging (FCM) Server Setup Instructions

To enable real push notifications on your Zudo B2B & B2C apps, you need to add Firebase credentials to your server's `.env` file. 

The server will automatically detect these variables. If they are missing, it will gracefully fall back to printing the notification parameters in the server console (mock mode).

---

## Step 1: Download your Firebase Service Account Private Key

1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Select your Firebase project: **`zudo-b55cc`**.
3. In the left sidebar, click the **Settings Cog (gear icon)** next to *Project Overview* and select **Project settings**.
4. Go to the **Service accounts** tab.
5. Click **Generate new private key** (at the bottom of the *Firebase Admin SDK* section).
6. Confirm by clicking **Generate key**.
7. A `.json` file containing your credentials will download to your computer. Open this file using any text editor (like Notepad or VS Code).

---

## Step 2: Add Variables to your `.env` File

Open your server's `.env` file (located at `c:\Users\nitinc\Desktop\Work\zudo\server\server\.env`) and append the following three variables using the values from your downloaded JSON file:

```env
# =========================================================================
# FIREBASE PUSH NOTIFICATION CONFIGURATION
# =========================================================================
FIREBASE_PROJECT_ID=zudo-b55cc
FIREBASE_CLIENT_EMAIL=your-service-account-email@zudo-b55cc.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
```

### ⚠️ CRITICAL private key formatting notes:
1. **Include quotes**: Make sure to wrap the `FIREBASE_PRIVATE_KEY` value in double quotes (`"..."`).
2. **One continuous line**: The private key must be a single, long line in the `.env` file. Do **not** press Enter or start new lines.
3. **Keep `\n` literals**: Ensure the newlines in the key are represented by `\n` characters (two separate characters: `\` and `n`) exactly as they appear in the downloaded JSON file. Do not replace them with actual newlines.

---

## Step 3: Restart the Server

Once you have added these environment variables, restart your Node.js server. 
The server console will now log:
`[FCM] Firebase Admin SDK successfully initialized using environment variables.`
And all B2B session close, cart abandonment, and other triggers will send real push notifications to your mobile devices!
