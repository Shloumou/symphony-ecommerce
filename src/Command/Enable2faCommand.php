<?php

namespace App\Command;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Scheb\TwoFactorBundle\Security\TwoFactor\Provider\Totp\TotpAuthenticatorInterface;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'app:enable-2fa',
    description: 'Enable 2FA for a user',
)]
class Enable2faCommand extends Command
{
    private EntityManagerInterface $em;
    private TotpAuthenticatorInterface $totpAuthenticator;

    public function __construct(EntityManagerInterface $em, TotpAuthenticatorInterface $totpAuthenticator)
    {
        parent::__construct();
        $this->em = $em;
        $this->totpAuthenticator = $totpAuthenticator;
    }

    protected function configure(): void
    {
        $this->addArgument('email', InputArgument::REQUIRED, 'User email');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $email = $input->getArgument('email');

        $user = $this->em->getRepository(User::class)->findOneBy(['email' => $email]);

        if (!$user) {
            $io->error(sprintf('User with email "%s" not found.', $email));
            return Command::FAILURE;
        }

        $secret = $this->totpAuthenticator->generateSecret();
        $user->setTotpSecret($secret);
        $this->em->flush();

        $qrContent = $this->totpAuthenticator->getQRContent($user);

        $io->success('2FA enabled successfully!');
        $io->section('QR Code Content (use with QR code generator):');
        $io->text($qrContent);
        $io->newLine();
        $io->section('Secret (manual entry):');
        $io->text($secret);

        return Command::SUCCESS;
    }
}
