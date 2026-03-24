# dot_files

Al dente configs. Firm, never mushy.

## Setup

After cloning, enable the pre-commit hook:

```sh
git config core.hooksPath hooks
```

This runs a scan on every commit that checks for:
- Leaked secrets (API keys, tokens, private keys)
- Suspicious Unicode (bidi overrides, zero-width chars) used in trojan source attacks
