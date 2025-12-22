# Contributing to La Boot'ique

Thank you for your interest in contributing to La Boot'ique! This document provides guidelines and instructions for contributing to the project.

## 📋 Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Documentation](#documentation)

---

## Code of Conduct

### Our Pledge
We are committed to providing a welcoming and inclusive environment for all contributors.

### Expected Behavior
- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

---

## Getting Started

### Prerequisites
- PHP 8.2 or higher
- Composer 2.x
- MySQL 8.0
- Git
- Docker (optional but recommended)

### Setting Up Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/ecommerce_web_site_with_sym.git
   cd ecommerce_web_site_with_sym-master
   ```

2. **Install Dependencies**
   ```bash
   composer install
   ```

3. **Configure Environment**
   ```bash
   cp .env .env.local
   # Edit .env.local with your configuration
   ```

4. **Setup Database**
   ```bash
   php bin/console doctrine:database:create
   php bin/console doctrine:migrations:migrate
   ```

5. **Start Development Server**
   ```bash
   symfony server:start
   # or
   docker-compose up -d
   ```

---

## Development Workflow

### Branching Strategy

We use the following branch naming conventions:

- `main` - Production-ready code
- `develop` - Development branch
- `feature/feature-name` - New features
- `bugfix/bug-description` - Bug fixes
- `hotfix/issue-description` - Critical production fixes
- `docs/documentation-update` - Documentation changes

### Creating a Feature Branch

```bash
# Update your local repository
git checkout develop
git pull origin develop

# Create a new feature branch
git checkout -b feature/your-feature-name
```

### Making Changes

1. Make your changes in your feature branch
2. Write or update tests as needed
3. Ensure all tests pass
4. Update documentation if necessary
5. Commit your changes with clear commit messages

### Commit Message Guidelines

Use clear and descriptive commit messages:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```bash
git commit -m "feat(cart): add quantity selector to cart items"
git commit -m "fix(payment): resolve stripe webhook validation error"
git commit -m "docs(readme): update installation instructions"
```

---

## Coding Standards

### PHP Standards

We follow [PSR-12](https://www.php-fig.org/psr/psr-12/) coding standards.

**Key Points:**
- Use 4 spaces for indentation
- Use camelCase for methods and variables
- Use PascalCase for class names
- Maximum line length of 120 characters
- Always use type hints when possible

**Example:**
```php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;

class ProductController extends AbstractController
{
    public function index(): Response
    {
        $products = $this->productRepository->findAll();
        
        return $this->render('product/index.html.twig', [
            'products' => $products,
        ]);
    }
}
```

### Symfony Best Practices

- Follow [Symfony Best Practices](https://symfony.com/doc/current/best_practices.html)
- Use Dependency Injection
- Keep controllers thin, move business logic to services
- Use Doctrine entities for database interactions
- Use Form Types for form handling
- Use Twig for templating

### Code Quality Tools

Run these before committing:

```bash
# PHP CS Fixer (code style)
./vendor/bin/php-cs-fixer fix src

# PHPStan (static analysis)
./vendor/bin/phpstan analyse src

# PHPUnit (tests)
./bin/phpunit
```

---

## Testing

### Writing Tests

All new features should include tests:

```php
<?php

namespace App\Tests\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class ProductControllerTest extends WebTestCase
{
    public function testProductListPageLoads(): void
    {
        $client = static::createClient();
        $client->request('GET', '/products');
        
        $this->assertResponseIsSuccessful();
        $this->assertSelectorTextContains('h1', 'Products');
    }
}
```

### Running Tests

```bash
# Run all tests
php bin/phpunit

# Run specific test file
php bin/phpunit tests/Controller/ProductControllerTest.php

# Run with coverage (requires Xdebug)
php bin/phpunit --coverage-html coverage/
```

### Test Coverage

- Aim for at least 70% code coverage
- All critical paths must have tests
- Test both success and failure scenarios

---

## Submitting Changes

### Pull Request Process

1. **Ensure Your Branch is Up to Date**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout your-feature-branch
   git rebase develop
   ```

2. **Push Your Branch**
   ```bash
   git push origin your-feature-branch
   ```

3. **Create Pull Request**
   - Go to GitHub repository
   - Click "New Pull Request"
   - Select your feature branch
   - Fill in the PR template

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added/updated
- [ ] All tests passing

## Screenshots (if applicable)
Add screenshots here

## Related Issues
Closes #issue_number
```

### Review Process

1. At least one maintainer must review the PR
2. All CI checks must pass
3. Address all review comments
4. Keep PR focused and reasonably sized
5. Be responsive to feedback

---

## Documentation

### Updating Documentation

When making changes that affect:
- User features → Update `README.md`
- Deployment → Update docs in `docs/deployment/`
- Security → Update docs in `docs/security/`
- API changes → Update relevant documentation

### Documentation Style

- Use clear, concise language
- Include code examples where appropriate
- Use proper Markdown formatting
- Keep documentation up to date with code changes

### Writing Good Documentation

**Do:**
- Explain WHY, not just WHAT
- Provide examples
- Keep it simple and clear
- Update as code changes

**Don't:**
- Assume prior knowledge
- Use jargon without explanation
- Leave outdated information
- Skip edge cases

---

## Areas for Contribution

### Good First Issues

Look for issues labeled `good-first-issue` on GitHub. These are:
- Well-defined
- Not too complex
- Good for new contributors

### Priority Areas

1. **Testing**
   - Write tests for untested code
   - Improve test coverage
   - Add integration tests

2. **Documentation**
   - Improve existing docs
   - Add code examples
   - Translate documentation

3. **Bug Fixes**
   - Fix reported bugs
   - Improve error handling
   - Enhance validation

4. **Features**
   - Implement requested features
   - Improve existing features
   - Add new payment methods

5. **Performance**
   - Optimize database queries
   - Improve page load times
   - Reduce memory usage

6. **Security**
   - Identify vulnerabilities
   - Implement security best practices
   - Update dependencies

---

## Getting Help

### Communication Channels

- **Issues**: For bug reports and feature requests
- **Pull Requests**: For code contributions
- **Discussions**: For questions and general discussion

### Questions?

If you have questions:
1. Check existing documentation
2. Search closed issues
3. Open a new discussion
4. Ask in pull request comments

---

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Appreciated in project documentation

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

**Thank you for contributing to La Boot'ique! 🎉**

Your contributions make this project better for everyone.
