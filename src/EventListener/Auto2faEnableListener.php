<?php

namespace App\EventListener;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Scheb\TwoFactorBundle\Security\TwoFactor\Provider\Totp\TotpAuthenticatorInterface;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\Security\Http\Event\InteractiveLoginEvent;
use Symfony\Component\Security\Http\SecurityEvents;

class Auto2faEnableListener implements EventSubscriberInterface
{
    private EntityManagerInterface $em;
    private TotpAuthenticatorInterface $totpAuthenticator;

    public function __construct(EntityManagerInterface $em, TotpAuthenticatorInterface $totpAuthenticator)
    {
        $this->em = $em;
        $this->totpAuthenticator = $totpAuthenticator;
    }

    public static function getSubscribedEvents(): array
    {
        return [
            SecurityEvents::INTERACTIVE_LOGIN => 'onInteractiveLogin',
        ];
    }

    public function onInteractiveLogin(InteractiveLoginEvent $event): void
    {
        $user = $event->getAuthenticationToken()->getUser();

        if (!$user instanceof User) {
            return;
        }

        // If user doesn't have 2FA enabled, enable it automatically
        if (!$user->getTotpSecret()) {
            $secret = $this->totpAuthenticator->generateSecret();
            $user->setTotpSecret($secret);
            $this->em->persist($user);
            $this->em->flush();

            // Store in session to show setup page
            $session = $event->getRequest()->getSession();
            $session->set('show_2fa_setup', true);
        }
    }
}
