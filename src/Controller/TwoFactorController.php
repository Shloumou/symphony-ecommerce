<?php

namespace App\Controller;

use Endroid\QrCode\Builder\Builder;
use Endroid\QrCode\Encoding\Encoding;
use Endroid\QrCode\ErrorCorrectionLevel\ErrorCorrectionLevelHigh;
use Endroid\QrCode\Writer\PngWriter;
use Scheb\TwoFactorBundle\Security\TwoFactor\Provider\Totp\TotpAuthenticatorInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\Session\SessionInterface;
use Symfony\Component\Routing\Annotation\Route;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Security\Core\Authentication\Token\Storage\TokenStorageInterface;
use Psr\Log\LoggerInterface;

class TwoFactorController extends AbstractController
{
    #[Route('/2fa', name: '2fa_login')]
    public function twoFactorLogin(
        SessionInterface $session, 
        TotpAuthenticatorInterface $totpAuthenticator,
        TokenStorageInterface $tokenStorage,
        LoggerInterface $logger
    ): Response {
        // During 2FA, the user is in the token but getUser() might return null
        // So we get it from the token storage directly
        $token = $tokenStorage->getToken();
        $user = $token ? $token->getUser() : null;
        
        $logger->info('2FA Login - User from token: ' . ($user ? get_class($user) : 'NULL'));
        
        // Check if we need to show the setup page
        if ($session->get('show_2fa_setup', false)) {
            $session->remove('show_2fa_setup');

            if ($user && method_exists($user, 'getTotpSecret') && $user->getTotpSecret()) {
                // Try to generate a PNG data URI for the QR code so it can be
                // displayed even in the 2FA flow where direct image routes
                // may not have access to the fully-authenticated user.
                $qrCodeDataUri = null;
                try {
                    $qrCodeContent = $totpAuthenticator->getQRContent($user);
                    $result = Builder::create()
                        ->writer(new PngWriter())
                        ->data($qrCodeContent)
                        ->encoding(new Encoding('UTF-8'))
                        ->errorCorrectionLevel(new ErrorCorrectionLevelHigh())
                        ->size(250)
                        ->margin(10)
                        ->build();

                    $qrCodeDataUri = 'data:image/png;base64,' . base64_encode($result->getString());
                    $logger->info('2FA Setup - QR Code data URI generated (setup flow)');
                } catch (\Exception $e) {
                    $logger->error('2FA Setup - QR Code generation failed: ' . $e->getMessage());
                    $qrCodeDataUri = null;
                }

                return $this->render('security/2fa_first_time_setup.html.twig', [
                    'user' => $user,
                    'qrCodeDataUri' => $qrCodeDataUri,
                ]);
            }
        }
        
        // Generate QR code data URI if user has a secret
        $qrCodeDataUri = null;
        if ($user && method_exists($user, 'getTotpSecret')) {
            $totpSecret = $user->getTotpSecret();
            $logger->info('2FA Login - User has TOTP secret: ' . ($totpSecret ? 'YES' : 'NO'));
            
            if ($totpSecret) {
                try {
                    $qrCodeContent = $totpAuthenticator->getQRContent($user);
                    $logger->info('2FA Login - QR Content generated: ' . substr($qrCodeContent, 0, 50) . '...');
                    
                    $result = Builder::create()
                        ->writer(new PngWriter())
                        ->data($qrCodeContent)
                        ->encoding(new Encoding('UTF-8'))
                        ->errorCorrectionLevel(new ErrorCorrectionLevelHigh())
                        ->size(250)
                        ->margin(10)
                        ->build();
                    
                    $qrCodeDataUri = 'data:image/png;base64,' . base64_encode($result->getString());
                    $logger->info('2FA Login - QR Code data URI generated successfully (length: ' . strlen($qrCodeDataUri) . ')');
                } catch (\Exception $e) {
                    // Log the error for debugging
                    $logger->error('QR Code generation failed: ' . $e->getMessage());
                    $qrCodeDataUri = null;
                }
            }
        } else {
            $logger->warning('2FA Login - User object issue. User: ' . ($user ? get_class($user) : 'null') . ', Has getTotpSecret: ' . (method_exists($user, 'getTotpSecret') ? 'YES' : 'NO'));
        }
        
        $logger->info('2FA Login - Rendering template with qrCodeDataUri: ' . ($qrCodeDataUri ? 'SET' : 'NULL'));
        
        // Pass user and QR code to template
        return $this->render('security/2fa_form.html.twig', [
            'user' => $user,
            'qrCodeDataUri' => $qrCodeDataUri,
        ]);
    }

    #[Route('/profile/2fa/enable', name: '2fa_enable')]
    public function enable2fa(TotpAuthenticatorInterface $totpAuthenticator, EntityManagerInterface $em): Response
    {
        $user = $this->getUser();

        if (!$user) {
            throw $this->createAccessDeniedException();
        }

        // Generate TOTP secret if not already set
        if (!$user->getTotpSecret()) {
            $secret = $totpAuthenticator->generateSecret();
            $user->setTotpSecret($secret);
            $em->persist($user);
            $em->flush();
        }

        // Generate QR code data URI so the user can scan it directly
        $qrCodeDataUri = null;
        try {
            $qrCodeContent = $totpAuthenticator->getQRContent($user);
            $result = Builder::create()
                ->writer(new PngWriter())
                ->data($qrCodeContent)
                ->encoding(new Encoding('UTF-8'))
                ->errorCorrectionLevel(new ErrorCorrectionLevelHigh())
                ->size(250)
                ->margin(10)
                ->build();

            $qrCodeDataUri = 'data:image/png;base64,' . base64_encode($result->getString());
        } catch (\Exception $e) {
            error_log('Failed to generate QR for enable2fa: ' . $e->getMessage());
            $qrCodeDataUri = null;
        }

        return $this->render('security/2fa_enable.html.twig', [
            'user' => $user,
            'qrCodeDataUri' => $qrCodeDataUri,
        ]);
    }

    #[Route('/profile/2fa/qr-code', name: '2fa_qr_code')]
    public function displayQrCode(TotpAuthenticatorInterface $totpAuthenticator): Response
    {
        $user = $this->getUser();
        
        if (!$user || !$user->getTotpSecret()) {
            throw $this->createAccessDeniedException();
        }

        $qrCodeContent = $totpAuthenticator->getQRContent($user);

        $result = Builder::create()
            ->writer(new PngWriter())
            ->data($qrCodeContent)
            ->encoding(new Encoding('UTF-8'))
            ->errorCorrectionLevel(new ErrorCorrectionLevelHigh())
            ->size(200)
            ->margin(0)
            ->build();

        return new Response($result->getString(), 200, ['Content-Type' => 'image/png']);
    }

    #[Route('/profile/2fa/disable', name: '2fa_disable', methods: ['POST'])]
    public function disable2fa(EntityManagerInterface $em): Response
    {
        $user = $this->getUser();
        
        if (!$user) {
            throw $this->createAccessDeniedException();
        }

        $user->setTotpSecret(null);
        $em->persist($user);
        $em->flush();

        $this->addFlash('success', '2FA has been disabled for your account.');

        return $this->redirectToRoute('app_account');
    }
}
