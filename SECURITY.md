# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.1.x   | ✅ Yes    |
| 1.0.x   | ❌ No     |

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability in PromptReel AI, please report it
responsibly by emailing:

**security@chastechgroup.com**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fix (optional)

We will acknowledge receipt within **48 hours** and aim to release a fix
within **7 days** for critical issues.

We will credit you in the release notes unless you prefer to remain anonymous.

## Scope

In scope:
- Backend API (`promptreel-ai.onrender.com`)
- Authentication and authorization bypass
- Payment flow vulnerabilities
- Data exposure / PII leaks
- Injection attacks (SQL, command)

Out of scope:
- Social engineering
- DoS/DDoS attacks
- Issues in third-party dependencies (report to them directly)
- Issues requiring physical access

## Security Measures in Place

- JWT authentication with short-lived access tokens (7 days) + refresh tokens
- bcrypt password hashing
- Rate limiting (200 req/min global, 10 req/min on auth endpoints)
- HTTPS enforced everywhere (HSTS)
- Security headers on all responses (CSP, X-Frame-Options, etc.)
- Input validation via Pydantic
- SQL injection prevented via SQLAlchemy ORM (parameterized queries)
- Webhook HMAC verification for Flutterwave
- No secrets in source code (all via environment variables)
