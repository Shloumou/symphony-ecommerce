<?php

namespace App\Command;

use App\Repository\UserRepository;
use Endroid\QrCode\Builder\Builder;
use Endroid\QrCode\Encoding\Encoding;
use Endroid\QrCode\ErrorCorrectionLevel\ErrorCorrectionLevelHigh;
use Endroid\QrCode\Writer\PngWriter;
use Scheb\TwoFactorBundle\Security\TwoFactor\Provider\Totp\TotpAuthenticatorInterface;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use OTPHP\TOTP;

#[AsCommand(
    name: 'app:show-totp',
    description: 'Display TOTP QR code and current 6-digit code for a user',
)]
class ShowTotpCommand extends Command
{
    public function __construct(
        private UserRepository $userRepository,
        private TotpAuthenticatorInterface $totpAuthenticator
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addArgument('email', InputArgument::REQUIRED, 'User email address')
            ->setHelp('This command displays the TOTP QR code (as base64 data URI) and the current 6-digit authentication code for a user.');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $email = $input->getArgument('email');

        // Find user
        $user = $this->userRepository->findOneBy(['email' => $email]);
        
        if (!$user) {
            $io->error("User with email '{$email}' not found.");
            return Command::FAILURE;
        }

        // Check if user has TOTP secret
        if (!$user->getTotpSecret()) {
            $io->warning("User '{$email}' does not have 2FA enabled (no TOTP secret found).");
            return Command::FAILURE;
        }

        $io->title("TOTP Information for: {$email}");

        // Display TOTP secret
        $io->section('TOTP Secret');
        $io->text($user->getTotpSecret());

        // Generate and display current TOTP code
        try {
            $totp = TOTP::create($user->getTotpSecret());
            $currentCode = $totp->now();
            
            $io->section('Current 6-Digit TOTP Code');
            $io->success($currentCode);
            $io->text('⚠️  This code expires in ' . (30 - (time() % 30)) . ' seconds');
        } catch (\Exception $e) {
            $io->error('Failed to generate current TOTP code: ' . $e->getMessage());
        }

        // Generate QR code
        try {
            $qrCodeContent = $this->totpAuthenticator->getQRContent($user);
            
            $io->section('QR Code Content (otpauth:// URI)');
            $io->text($qrCodeContent);

            // Generate QR code as base64 data URI
            $result = Builder::create()
                ->writer(new PngWriter())
                ->data($qrCodeContent)
                ->encoding(new Encoding('UTF-8'))
                ->errorCorrectionLevel(new ErrorCorrectionLevelHigh())
                ->size(300)
                ->margin(10)
                ->build();

            $qrCodeDataUri = 'data:image/png;base64,' . base64_encode($result->getString());

            $io->section('QR Code (Base64 Data URI)');
            $io->text('Copy this data URI and paste it in your browser address bar to view the QR code:');
            $io->newLine();
            $io->text($qrCodeDataUri);
            $io->newLine();
            
            $io->note('You can also scan this QR code from the web interface at /profile/2fa/enable or /2fa');

        } catch (\Exception $e) {
            $io->error('Failed to generate QR code: ' . $e->getMessage());
            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }
}
