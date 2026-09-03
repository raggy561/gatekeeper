# GateKeeper - DevSecOps Pipeline - Security-as-Code (GitHub Actions)

![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?logo=githubactions&logoColor=white)
![Checkov](https://img.shields.io/badge/Checkov-IaC_Scan-0FB39A)
![DevSecOps](https://img.shields.io/badge/DevSecOps-security_as_code-EDA53A)

A CI/CD pipeline that automatically scans infrastructure-as-code for security issues on every commit — shifting security *left*, before anything reaches AWS.

> Demonstrates DevSecOps: security isn't a gate at the end, it's an automated check baked into the build.

---

## What the pipeline does
<!-- Adjust to your actual workflow -->
On every push / pull request, GitHub Actions:
1. Runs **Checkov** (and/or **tfsec**) against the Terraform in [Terradome](https://github.com/<your-username>/terradome)
2. **Fails the build** on HIGH-severity findings, blocking insecure infrastructure from merging
3. Posts results as a summary / PR comment for reviewers
4. *(Stretch)* Runs a secrets-scan step to catch committed credentials

## Pipeline flow
```
push / PR
   │
   ├─ checkout
   ├─ Checkov / tfsec scan  ──►  HIGH finding? ──► ❌ fail build
   ├─ (secrets scan)
   └─ ✅ pass → report results
```

---

## Security decisions
| Choice | Decision | Why |
|--------|----------|-----|
| Fail on HIGH | Build breaks on high-severity IaC findings | Insecure infra never reaches production |
| Shift left | Scanning runs pre-merge, not post-deploy | Cheapest place to catch a misconfig is before it exists |
| Least-privilege CI | Workflow token scoped to minimum needed | The pipeline itself follows the principles it enforces |
| Visible results | Findings surfaced in PR, not buried in logs | Security feedback where developers actually see it |
<!-- Edit to match your workflow -->

---

## How to use
The workflow lives in `.github/workflows/<!-- name -->.yml`. Point it at a Terraform repo and it runs automatically on push/PR.

```yaml
# Excerpt — see the full workflow file
<!-- paste the key steps of your actual workflow here -->
```

To run the scan locally:
```bash
pip install checkov
checkov -d ./path-to-terraform
```

---

## What I learned
<!-- e.g., tuning which severities fail the build, a real finding Checkov caught in your own Terraform, workflow permission scoping. -->
-
-

---

**Hansley Jean** — Cloud Security Engineer
AWS Certified Security – Specialty · Microsoft Certified: Azure Security Engineer (AZ-500)
[LinkedIn](https://linkedin.com/in/hansley-j-0522711b9) · [GitHub](https://github.com/<your-username>)
