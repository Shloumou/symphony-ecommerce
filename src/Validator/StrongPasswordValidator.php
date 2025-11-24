<?php

namespace App\Validator;

use Symfony\Component\Validator\Constraint;
use Symfony\Component\Validator\ConstraintValidator;
use Symfony\Component\Validator\Exception\UnexpectedTypeException;
use Symfony\Component\Validator\Exception\UnexpectedValueException;

class StrongPasswordValidator extends ConstraintValidator
{
    public function validate($value, Constraint $constraint): void
    {
        if (!$constraint instanceof StrongPassword) {
            throw new UnexpectedTypeException($constraint, StrongPassword::class);
        }

        // Allow null or empty values (use NotBlank constraint separately for that)
        if (null === $value || '' === $value) {
            return;
        }

        if (!is_string($value)) {
            throw new UnexpectedValueException($value, 'string');
        }

        $violations = [];

        // Check minimum length
        if (strlen($value) < $constraint->minLength) {
            $this->context->buildViolation($constraint->tooShortMessage)
                ->setParameter('{{ min_length }}', (string) $constraint->minLength)
                ->addViolation();
            return; // Don't check other requirements if too short
        }

        // Check for uppercase letter
        if ($constraint->requireUppercase && !preg_match('/[A-Z]/', $value)) {
            $this->context->buildViolation($constraint->missingUppercaseMessage)
                ->addViolation();
        }

        // Check for lowercase letter
        if ($constraint->requireLowercase && !preg_match('/[a-z]/', $value)) {
            $this->context->buildViolation($constraint->missingLowercaseMessage)
                ->addViolation();
        }

        // Check for number
        if ($constraint->requireNumbers && !preg_match('/[0-9]/', $value)) {
            $this->context->buildViolation($constraint->missingNumberMessage)
                ->addViolation();
        }

        // Check for special character
        if ($constraint->requireSpecialChars && !preg_match('/[^A-Za-z0-9]/', $value)) {
            $this->context->buildViolation($constraint->missingSpecialCharMessage)
                ->addViolation();
        }
    }
}
