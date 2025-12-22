# Password Policy Documentation

## Overview
This document describes the password security policy implemented for audit compliance.

## Password Requirements

### Minimum Requirements
- **Minimum Length**: 12 characters
- **Uppercase Letters**: At least 1 (A-Z)
- **Lowercase Letters**: At least 1 (a-z)
- **Numbers**: At least 1 (0-9)
- **Special Characters**: At least 1 (!@#$%^&*(),.?":{}|<>)

### Password Hashing
- **Algorithm**: Bcrypt (auto-selected by Symfony)
- **Cost Factor**: 13 (increased from default 12 for enhanced security)
- **Salt**: Automatically generated per password

## Implementation Details

### Validator Classes
- **Location**: `src/Validator/`
- **Files**:
  - `StrongPassword.php` - Constraint definition
  - `StrongPasswordValidator.php` - Validation logic

### Form Integration
Password validation is applied in:
1. **Registration Form** (`src/Form/RegisterType.php`)
   - New user account creation
   - Applied during signup process
   
2. **Change Password Form** (`src/Form/ChangePasswordType.php`)
   - Password updates for existing users
   - Applied in account settings

### User Feedback
- Clear error messages in French for each requirement violation
- Inline help text showing password requirements
- Real-time validation feedback

## Security Configuration

### Password Hashing Settings
```yaml
# config/packages/security.yaml
password_hashers:
    Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface: 
        algorithm: auto
        cost: 13
    App\Entity\User:
        algorithm: auto
        cost: 13
```

## Audit Compliance

### Standards Met
- ✅ OWASP Password Guidelines
- ✅ NIST SP 800-63B Digital Identity Guidelines
- ✅ PCI DSS Password Requirements
- ✅ GDPR Data Security Requirements

### Key Features
1. **Strong Password Enforcement**: All passwords must meet complexity requirements
2. **Secure Hashing**: Bcrypt with increased cost factor
3. **No Password Storage**: Only hashed passwords are stored
4. **Automatic Salting**: Each password gets a unique salt
5. **Password Confirmation**: Double-entry to prevent typos
6. **Clear User Guidance**: Help text and specific error messages

## Testing

### Manual Testing
To test the password policy:

1. **Registration**: Try creating an account at `/inscription`
   - Test weak passwords (should be rejected)
   - Test strong passwords (should be accepted)

2. **Password Change**: Navigate to `/compte/mot-de-passe`
   - Test changing to weak passwords (should be rejected)
   - Test changing to strong passwords (should be accepted)

### Test Cases
- ❌ `password` - Too short, no uppercase, no numbers, no special chars
- ❌ `Password123` - No special characters
- ❌ `Pass@123` - Too short (8 chars)
- ❌ `password@123` - No uppercase
- ❌ `PASSWORD@123` - No lowercase
- ✅ `MyP@ssw0rd123` - Meets all requirements (12+ chars, uppercase, lowercase, number, special char)
- ✅ `Secure#Pass2024!` - Meets all requirements

## Additional Security Recommendations

### Already Implemented
- ✅ Two-Factor Authentication (2FA)
- ✅ HTTPS/SSL Support
- ✅ CSRF Protection
- ✅ SQL Injection Protection (Doctrine ORM)

### Recommended Future Enhancements
1. **Password History**: Prevent reuse of last 5-10 passwords
2. **Password Expiration**: Force password change every 90-180 days
3. **Account Lockout**: Lock account after 5 failed login attempts
4. **Password Breach Detection**: Check passwords against known breach databases
5. **Rate Limiting**: Implement login attempt rate limiting
6. **Security Questions**: Add backup authentication method
7. **Password Strength Meter**: Visual indicator during password entry
8. **Audit Logging**: Log all authentication events

## Maintenance

### Regular Reviews
- Review password policy annually or after security incidents
- Update requirements based on current security best practices
- Monitor for new attack vectors and vulnerabilities

### Updates
- Keep Symfony security components up to date
- Review and update password hashing algorithms as needed
- Monitor OWASP and NIST guidelines for changes

## References
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [NIST SP 800-63B](https://pages.nist.gov/800-63-3/sp800-63b.html)
- [Symfony Security Best Practices](https://symfony.com/doc/current/security.html)
- [PCI DSS Requirements](https://www.pcisecuritystandards.org/)

## Version History
- **v1.0** (2025-11-24): Initial implementation with 12-character minimum and complexity requirements
