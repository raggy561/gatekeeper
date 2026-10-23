# examples/insecure.tf
# ⚠️ INTENTIONALLY INSECURE — a test fixture to prove the CI scanner
# catches misconfigurations. The pipeline SHOULD fail on this file.

resource "aws_s3_bucket" "bad" {
  bucket = "devsecops-demo-insecure-bucket"
}

# No encryption, no public access block -> Checkov will flag these.

resource "aws_security_group" "wide_open" {
  name = "wide-open"

  ingress {
    description = "SSH open to the entire internet (bad!)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # Checkov will flag this
  }
}