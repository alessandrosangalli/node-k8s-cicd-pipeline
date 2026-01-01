# Enable Services for Binary Authorization
resource "google_project_service" "binary_authorization" {
  service = "binaryauthorization.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container_analysis" {
  service = "containeranalysis.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudkms" {
  service = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

# 1. KMS Key for signing Attestations
resource "google_kms_key_ring" "binauth_key_ring" {
  name     = "binauth-key-ring"
  location = var.region
  depends_on = [google_project_service.cloudkms]
}

resource "google_kms_crypto_key" "binauth_key" {
  name     = "binauth-signer-key"
  key_ring = google_kms_key_ring.binauth_key_ring.id
  purpose  = "ASYMMETRIC_SIGN"
  
  version_template {
    algorithm = "RSA_SIGN_PKCS1_4096_SHA512"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 2. Container Analysis Note (The "Authority")
resource "google_container_analysis_note" "attestor_note" {
  name = "binauth-attestor-note"
  
  attestation_authority {
    hint {
      human_readable_name = "CI/CD Pipeline Attestor"
    }
  }

  depends_on = [google_project_service.container_analysis]
}

# 3. Binary Authorization Attestor
# Connects the Note with the KMS Key
resource "google_binary_authorization_attestor" "ci_attestor" {
  name = "ci-pipeline-attestor"
  
  attestation_authority_note {
    note_reference = google_container_analysis_note.attestor_note.name
    
    public_keys {
      id = data.google_kms_crypto_key_version.binauth_key_version.id
      pkix_public_key {
        public_key_pem = data.google_kms_crypto_key_version.binauth_key_version.public_key[0].pem
        signature_algorithm = data.google_kms_crypto_key_version.binauth_key_version.public_key[0].algorithm
      }
    }
  }

  depends_on = [google_project_service.binary_authorization]
}

# Data source to get the public key from the created key version
data "google_kms_crypto_key_version" "binauth_key_version" {
  crypto_key = google_kms_crypto_key.binauth_key.id
}

# 4. Binary Authorization Policy
resource "google_binary_authorization_policy" "policy" {
  
  # Default rule for all images
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "DRYRUN_AUDIT_LOG_ONLY" # Start safe! Change to ENFORCED_BLOCK_AND_AUDIT_LOG later.
    require_attestations_by = [google_binary_authorization_attestor.ci_attestor.name]
  }

  # Allow Google system images (GKE internals)
  global_policy_evaluation_mode = "ENABLE"

  # Whitelist some common system patterns if needed, but 'global_policy_evaluation_mode = ENABLE' handles most Google stuff.
  # Explicitly allow images from our project's artifact registry (sanity check)
  # But the goal is to require attestation for everything not global.
}

# 5. IAM Binding for the Attestor
# The usage of this attestor requires permission
# In a real scenario, the CI/CD Service Account needs 'roles/binaryauthorization.attestorsViewer' 
# and 'roles/cloudkms.signerVerifier' and 'roles/containeranalysis.notes.attacher'.
# We will create a service account for the CI/CD pipeline to use.

resource "google_service_account" "cicd_attestor" {
  account_id   = "cicd-attestor-sa"
  display_name = "CI/CD Pipeline Attestor SA"
}

# Permission to view Attestors
resource "google_project_iam_member" "attestor_viewer" {
  project = var.project_id
  role    = "roles/binaryauthorization.attestorsViewer"
  member  = "serviceAccount:${google_service_account.cicd_attestor.email}"
}

# Permission to Sign with KMS
resource "google_project_iam_member" "kms_signer" {
  project = var.project_id
  role    = "roles/cloudkms.signerVerifier"
  member  = "serviceAccount:${google_service_account.cicd_attestor.email}"
}

# Permission to Attach Notes (Create Occurrences)
resource "google_project_iam_member" "note_attacher" {
  project = var.project_id
  role    = "roles/containeranalysis.notes.attacher"
  member  = "serviceAccount:${google_service_account.cicd_attestor.email}"
}

# Permission to create occurrences (Required for sign-and-create)
resource "google_project_iam_member" "occurrence_editor" {
  project = var.project_id
  role    = "roles/containeranalysis.occurrences.editor"
  member  = "serviceAccount:${google_service_account.cicd_attestor.email}"
}

# Grant access to the Note explicitly
resource "google_container_analysis_note_iam_member" "note_iam" {
  note = google_container_analysis_note.attestor_note.name
  role = "roles/containeranalysis.notes.attacher"
  member = "serviceAccount:${google_service_account.cicd_attestor.email}"
}

output "cicd_attestor_email" {
  value = google_service_account.cicd_attestor.email
  description = "Service Account email for CI/CD to use for signing"
}
