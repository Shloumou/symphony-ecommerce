<?php

namespace App\Validator;

use Symfony\Component\Validator\Constraint;

/**
 * @Annotation
 */
#[\Attribute]
class StrongPassword extends Constraint
{
    public string $message = 'Le mot de passe doit contenir au moins {{ min_length }} caractères, incluant au moins une majuscule, une minuscule, un chiffre et un caractère spécial (!@#$%^&*(),.?":{}|<>).';
    public string $tooShortMessage = 'Le mot de passe doit contenir au moins {{ min_length }} caractères.';
    public string $missingUppercaseMessage = 'Le mot de passe doit contenir au moins une lettre majuscule.';
    public string $missingLowercaseMessage = 'Le mot de passe doit contenir au moins une lettre minuscule.';
    public string $missingNumberMessage = 'Le mot de passe doit contenir au moins un chiffre.';
    public string $missingSpecialCharMessage = 'Le mot de passe doit contenir au moins un caractère spécial (!@#$%^&*(),.?":{}|<>).';
    public int $minLength = 12;
    public bool $requireUppercase = true;
    public bool $requireLowercase = true;
    public bool $requireNumbers = true;
    public bool $requireSpecialChars = true;
}
