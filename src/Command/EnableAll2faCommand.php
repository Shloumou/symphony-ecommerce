<?php

namespace App\Command;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Scheb\TwoFactorBundle\Security\TwoFactor\Provider\Totp\TotpAuthenticatorInterface;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'app:enable-all-2fa',
    description: 'Enable 2FA for all users who don\'t have it yet',
)]
class EnableAll2faCommand extends Command
{
    private EntityManagerInterface $em;
    private TotpAuthenticatorInterface $totpAuthenticator;

    public function __construct(
        EntityManagerInterface $em,
        TotpAuthenticatorInterface $totpAuthenticator
    ) {
        parent::__construct();
        $this->em = $em;
        $this->totpAuthenticator = $totpAuthenticator;
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);

        $userRepository = $this->em->getRepository(User::class);
        $users = $userRepository->findAll();

        $enabledCount = 0;
        $skippedCount = 0;

        foreach ($users as $user) {
            if (!$user->getTotpSecret()) {
                $secret = $this->totpAuthenticator->generateSecret();
                $user->setTotpSecret($secret);
                $this->em->persist($user);
                $enabledCount++;
                
                $io->writeln("✓ Enabled 2FA for: {$user->getEmail()}");
            } else {
                $skippedCount++;
                $io->writeln("- Skipped (already has 2FA): {$user->getEmail()}", OutputInterface::VERBOSITY_VERBOSE);
            }
        }

        $this->em->flush();

        $io->success([
            "2FA enablement complete!",
            "Enabled for $enabledCount users",
            "Skipped $skippedCount users (already had 2FA)"
        ]);

        return Command::SUCCESS;
    }
}
