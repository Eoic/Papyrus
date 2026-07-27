# Security Policy

## Scope

This policy applies to all projects maintained by the [PapyrusReader](https://github.com/PapyrusReader) organization.

Security issues may include vulnerabilities in the client, server, reader, website, documentation tooling, build pipelines, dependencies, authentication flows, synchronization, file handling, or supported storage integrations.

## Supported versions

Security fixes are generally applied to:

1. The current default branch.
2. The latest published release, when a release exists.

Older releases may not receive security updates. Users should update to the latest available version before reporting an issue that may already have been fixed.

## Reporting a vulnerability

Do not report security vulnerabilities through public GitHub issues, discussions, pull requests, or Trello cards.

Use GitHub's private vulnerability reporting:

1. Open the relevant PapyrusReader repository.
2. Select the **Security** tab.
3. Select **Report a vulnerability**.
4. Provide the requested details and submit the report privately.

When a vulnerability affects multiple PapyrusReader projects, report it through the repository where the issue is most directly exposed and list all affected projects in the report.

Include as much of the following information as possible:

* A description of the vulnerability and its potential impact.
* The affected project, version, platform, and configuration.
* Steps required to reproduce the issue.
* A minimal proof of concept, logs, screenshots, or relevant code.
* Any known prerequisites or limitations.
* Whether the issue is already being actively exploited or publicly known.
* Suggested remediation, when available.

Do not include real credentials, personal data, copyrighted books, or other sensitive third-party data in the report. Use redacted or synthetic test data where possible.

## What to expect

The maintainers will review the report, determine its impact and severity, and communicate through the private GitHub advisory.

We may request additional information or reproduction steps. Reports that cannot be reproduced or do not describe a security impact may be closed with an explanation.

When a vulnerability is confirmed, the maintainers will coordinate remediation and disclosure. The advisory may remain private until a fix is available and users have had a reasonable opportunity to update.

## Responsible disclosure

Give the maintainers a reasonable opportunity to investigate and address the issue before publishing technical details.

Do not:

* Access, modify, or delete data that does not belong to you.
* Degrade or disrupt PapyrusReader services or infrastructure.
* Perform denial-of-service testing.
* Use automated scanning that creates excessive traffic.
* Attempt social engineering, phishing, or physical attacks.
* Retain or disclose sensitive data discovered during testing.

Testing should be limited to systems, accounts, devices, and data that you own or are explicitly authorized to use.

## Out of scope

The following are generally not considered security vulnerabilities unless they create a concrete security impact:

* Bugs that only affect unsupported versions.
* Missing security headers without a demonstrated impact.
* Self-XSS requiring users to execute arbitrary code themselves.
* Reports based only on automated scanner output.
* Denial-of-service issues requiring excessive or unrealistic resources.
* Social engineering or phishing.
* Vulnerabilities in third-party services with no PapyrusReader-specific impact.
* Issues that require a rooted, jailbroken, or otherwise compromised device, unless the impact exceeds what that access already permits.
* Exposure of non-sensitive public information.

## Security-related contributions

Do not submit a public pull request for an undisclosed vulnerability.

Fixes should be coordinated through the private vulnerability report. A maintainer may create a private fork or invite contributors to collaborate on the GitHub security advisory.
