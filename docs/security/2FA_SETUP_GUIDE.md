# Two-Factor Authentication (2FA) Setup Guide

## Overview
The ecommerce application now has Two-Factor Authentication (TOTP) enabled for all users and admins.

## How 2FA Works

1. **First Login**: User enters email and password as usual
2. **2FA Prompt**: After successful password authentication, user is redirected to enter a 6-digit code
3. **Code Verification**: User opens their authenticator app (Google Authenticator, Microsoft Authenticator, etc.) and enters the current code
4. **Access Granted**: Upon successful verification, user gains full access

## Enabling 2FA for Users

### Method 1: Via Web Interface (User Self-Service)
Users can enable 2FA themselves:

1. Login to the account
2. Navigate to `/profile/2fa/enable`
3. Scan the QR code with an authenticator app
4. Enter the 6-digit code to verify setup

### Method 2: Via Command Line (Admin)
Administrators can enable 2FA for any user:

```bash
kubectl -n ecommerce exec deployment/ecommerce-app -- \
  php bin/console app:enable-2fa user@example.com
```

This will output:
- QR code content URL (otpauth://...)
- Secret key for manual entry

## Testing 2FA

### For Admin User
```bash
# Enable 2FA for admin
kubectl -n ecommerce exec deployment/ecommerce-app -- \
  php bin/console app:enable-2fa admin@ecommerce.local

# The command will output something like:
# otpauth://totp/Ecommerce%20Symfony:admin@ecommerce.local?secret=ABCDEFGH12345678&issuer=Ecommerce+Symfony
```

## Authenticator Apps

Users can use any TOTP-compatible authenticator app:
- **Google Authenticator** (iOS/Android)
- **Microsoft Authenticator** (iOS/Android)
- **Authy** (iOS/Android/Desktop)
- **1Password** (with TOTP support)
- **Bitwarden** (with TOTP support)

## Routes

- `/login` - Standard login page
- `/2fa` - Two-factor authentication code entry page
- `/profile/2fa/enable` - Enable 2FA and view QR code
- `/profile/2fa/qr-code` - Get QR code image
- `/profile/2fa/disable` - Disable 2FA (POST request)

## Disabling 2FA for a User

### Via Web Interface
Users can disable their own 2FA:
1. Login (with 2FA code)
2. Navigate to account settings
3. Click "Disable 2FA" button

### Via Database
```bash
# Disable 2FA for a user by clearing their TOTP secret
kubectl -n ecommerce exec deployment/mysql -- \
  mysql -uroot -pchangeme_root_password ecommerce_db \
  -e "UPDATE \`user\` SET totp_secret = NULL WHERE email = 'user@example.com';"
```

## Security Configuration

The 2FA setup in `config/packages/scheb_2fa.yaml`:
- **Algorithm**: SHA1 (standard TOTP)
- **Window**: 30 seconds
- **Digits**: 6
- **Tolerance**: 1 window (allows for clock drift)

## Database Schema

A new column `totp_secret` has been added to the `user` table:
```sql
ALTER TABLE `user` ADD COLUMN `totp_secret` VARCHAR(255) NULL DEFAULT NULL;
```

- If `totp_secret` is NULL, 2FA is disabled for that user
- If `totp_secret` contains a value, 2FA is enabled and required

## Troubleshooting

### User Locked Out (Lost Authenticator)
Admin can disable 2FA via database:
```bash
kubectl -n ecommerce exec deployment/mysql -- \
  mysql -uroot -pchangeme_root_password ecommerce_db \
  -e "UPDATE \`user\` SET totp_secret = NULL WHERE email = 'locked-out-user@example.com';"
```

### Invalid Code Error
- Check that device time is synchronized (TOTP is time-based)
- Try the previous or next code (window tolerance)
- Regenerate the secret if issue persists

### 2FA Not Prompting
- Ensure user has a `totp_secret` value in the database
- Check that `scheb_2fa.yaml` configuration is loaded
- Verify security.yaml has `two_factor:` section under firewall

## Application Access

- **URL**: http://192.168.49.2:31224
- **Admin Login**: admin@ecommerce.local / admin123
- **2FA Status**: Not yet enabled (use command above to enable)

## Next Steps

1. Enable 2FA for the admin account using the CLI command
2. Test login flow with 2FA enabled
3. Enable 2FA for regular users as needed
4. Consider making 2FA mandatory for ROLE_ADMIN users
