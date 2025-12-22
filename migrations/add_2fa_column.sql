-- Add totp_secret column for 2FA support
ALTER TABLE `user` ADD COLUMN `totp_secret` VARCHAR(255) NULL DEFAULT NULL;
