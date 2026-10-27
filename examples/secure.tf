# examples/secure.tf
# Hardened counterparts to what GateKeeper flagged in insecure.tf.
# Designed to PASS the scan — this is the remediation.

# --- S3: private, versioned, encrypted ---
# tfsec risk acceptance: access logging to a separate bucket is out of scope here
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "good" {
  # Documented risk acceptances — controls out of scope for a lab demo.
  #checkov:skip=CKV_AWS_145:SSE-S3 (AES256) is sufficient for demo; no CMK needed
  #checkov:skip=CKV_AWS_144:Cross-region replication not required for a demo bucket
  #checkov:skip=CKV_AWS_18:Access logging to a separate bucket is out of scope here
  #checkov:skip=CKV2_AWS_62:S3 event notifications out of scope for this demo
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration out of scope for this demo
  bucket = "gatekeeper-demo-secure-bucket"
}

resource "aws_s3_bucket_public_access_block" "good" {
  bucket                  = aws_s3_bucket.good.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "good" {
  bucket = aws_s3_bucket.good.id
  versioning_configuration {
    status = "Enabled"
  }
}

# tfsec risk acceptance: SSE-S3 (AES256) is sufficient for demo; no CMK needed
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "good" {
  bucket = aws_s3_bucket.good.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Security group: SSH restricted to an admin range, not the world ---
resource "aws_security_group" "locked_down" {
  #checkov:skip=CKV_AWS_382:Egress to internet on 443 needed for package updates
  #checkov:skip=CKV2_AWS_5:Standalone demo SG; no instance/ENI defined in this example
  name        = "locked-down"
  description = "SSH from a specific admin network only"

  ingress {
    description = "SSH from admin network only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]   # private admin/VPN range, NOT public internet
  }

  egress {
    description = "HTTPS outbound for updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # tfsec risk acceptance: egress to internet on 443 needed for package updates
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }
}