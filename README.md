# GateKeeper — DevSecOps Pipeline · Security-as-Code (GitHub Actions)

![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?logo=githubactions&logoColor=white)
![Checkov](https://img.shields.io/badge/Checkov-IaC_Scan-0FB39A)
![tfsec](https://img.shields.io/badge/tfsec-IaC_Scan-5C4EE5)
![DevSecOps](https://img.shields.io/badge/DevSecOps-security_as_code-EDA53A)

A CI/CD pipeline that automatically scans infrastructure-as-code for security misconfigurations on **every commit** — using two independent scanners — and fails the build when it finds problems. Security shifted *left*, before any Terraform is ever applied.

> Demonstrates DevSecOps: security isn't a gate at the end, it's an automated check baked into the build. Nothing is deployed — the scanners read the Terraform statically, so misconfigurations are caught before they ever cost money or exist in AWS.

---

## What the pipeline does

On every push and pull request, GitHub Actions runs two jobs in parallel against the Terraform in [`examples/`](examples/):

1. **Checkov** — policy-as-code IaC scanning
2. **tfsec** — a second, independent IaC scanner

If **either** scanner reports a violation, the build **fails** — blocking insecure infrastructure from being merged. Both run on ephemeral GitHub-hosted runners that are destroyed after each run.

### Why two scanners (defense in depth)
Checkov and tfsec ship different rulesets, so one catches what the other misses. That isn't theoretical here — see the real example below.

## Pipeline flow
```
push / PR
   │
   ├─ job: checkov ─┐
   │                ├─► any violation? ──► ❌ fail the build
   ├─ job: tfsec  ──┘
   │
   └─ both clean ──► ✅ pass
```

---

## The gate in action (before → after)

This repo deliberately started with an **insecure Terraform fixture** to prove the gate works:

- **Before** — `examples/insecure.tf` (unencrypted bucket, no public-access block, SSH open to `0.0.0.0/0`) → the pipeline failed ❌, listing every violation.
- **After** — remediated in `examples/secure.tf` (encrypted, versioned, private bucket; SSH restricted to a private range) → the pipeline passes ✅.

**The payoff finding:** tfsec flagged SSH exposed to a **publicly-routable range** that Checkov passed clean. That one finding is the entire justification for running two scanners — a single tool would have shipped the exposure.

---

## Fix vs. accept — documented risk decisions

Not every finding gets "fixed." Real security work means deciding, per finding, whether to **remediate** or **formally accept** the risk — and documenting it. This repo shows both:

- **Remediated** — genuine exposures (public SSH ingress) are fixed outright.
- **Accepted with a reason** — enterprise-grade controls out of scope for a lab (customer-managed KMS keys, cross-region replication, access logging) are suppressed with an inline, justified comment:
  ```hcl
  #checkov:skip=CKV_AWS_145:SSE-S3 (AES256) is sufficient for this lab; no CMK needed
  #tfsec:ignore:aws-s3-enable-bucket-logging
  ```

Knowing the difference between fixing a finding and accepting it — with a written justification — is the distinction between running a tool and operating a program.

---

## Security decisions

| Choice | Decision | Why |
|--------|----------|-----|
| Two scanners | Checkov **and** tfsec on every run | Independent rulesets — one catches what the other misses (proven: tfsec flagged a public SSH range Checkov passed) |
| Fail the build | Any violation breaks CI | Insecure IaC can't be merged; the gate has teeth |
| Shift left | Static scan runs pre-merge, never deploys | Cheapest, safest place to catch a misconfig is before it exists — zero AWS cost |
| Least-privilege CI | `permissions: contents: read` on the workflow token | The pipeline follows the principle it enforces |
| Documented exceptions | Every skip/ignore carries a written reason | Accepted risk is explicit and auditable, not silent |

---

## How to use

The workflow lives in [`.github/workflows/security-scan.yml`](.github/workflows/security-scan.yml) and runs automatically on push/PR.

```yaml
# Excerpt — two parallel scanner jobs
jobs:
  checkov:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install checkov
      - run: checkov --directory . --framework terraform --compact

  tfsec:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/tfsec-action@v1.0.3
        with: { working_directory: . }
```

Run the same scans locally before you push:

```bash
pip install checkov
checkov -d ./examples

# tfsec
brew install tfsec   # or: see github.com/aquasecurity/tfsec
tfsec ./examples
```

---

## What I learned

- **Two scanners earn their keep.** tfsec flagged SSH open to `203.0.113.0/24` — a publicly-routable documentation range — as CRITICAL, while Checkov passed it. That single catch justified the whole defense-in-depth approach and changed how I think about tooling: never trust one scanner's silence.
- **Fix vs. accept is the real skill.** Getting to green wasn't about silencing everything — it was deciding, per finding, whether to remediate (public ingress → fixed) or accept with a documented reason (no CMK, no replication → out of scope for a lab). That judgment, written down, is what makes a pipeline auditable.
- **Static analysis is free and fearless.** Because the scanners read the Terraform rather than applying it, the entire gate runs with zero AWS cost and zero deployed resources — you catch the problem by reading the code, before it ever exists.

---

## Roadmap

- **Severity threshold** — fail only on HIGH/CRITICAL, report lower severities without breaking the build
- **PR annotations** — surface findings as inline pull-request comments, not just Actions logs
- **Secrets scanning** — add gitleaks/trufflehog to catch committed credentials
- **Wire into Terradome** — run this workflow against the live [Terradome](https://github.com/<your-username>/terradome) landing zone, gating real infra changes
- **Promote lab skips to enforced controls** — convert the documented risk acceptances (KMS CMK, access logging, replication) into required checks for a production profile

---

**Hansley Jean** — Cloud Security Engineer
AWS Certified Security – Specialty · HashiCorp Certified: Terraform Associate · Microsoft Certified: Azure Security Engineer (AZ-500)
[LinkedIn](https://linkedin.com/in/hansley-j-0522711b9) · [GitHub](https://github.com/raggy561)