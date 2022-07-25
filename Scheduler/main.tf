
variable "project_id" {
  description = "testinfra-357317"
}

variable "region" {
  description = "us-central1"
}

data "archive_file" "src" {
  type        = "zip"
  source_dir  = "${path.root}/helloworldjs" # Directory where your Python source code is
  output_path = "${path.root}/src.zip"
}


resource "google_storage_bucket" "bucket" {
project = "testinfra-357317"
 name   = "renduterrabucket"
 location = "us-central1"
}
resource "google_storage_bucket_object" "archive" {
  name   = "${data.archive_file.src.output_md5}.zip"
  bucket = google_storage_bucket.bucket.name
  source = "${path.root}/src.zip"
}

resource "google_cloudfunctions_function" "function" {
    project = "testinfra-357317"
    region = "us-central1"
  name        = "scheduled-cloud-function-rendu"
  description = "An Cloud Function "
  runtime     = "nodejs16"


  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = true
  entry_point           = "helloWorld" # This is the name of the function that will be executed in the code
}

resource "google_service_account" "service_account" {
  project = "testinfra-357317"
  
  account_id   = "invoker-renduterra"
  display_name = "Invoker Service rendu terra"
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_cloud_scheduler_job" "job" {
  name             = "cloud-function-tutorial-scheduler"
   project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  description      = "Trigger the ${google_cloudfunctions_function.function.name} Cloud Function every 10 mins."
  schedule         = "0 7 * * *" # Every 7 hours
  //time_zone        = "Europe/Dublin"
  attempt_deadline = "320s"

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions_function.function.https_trigger_url

    oidc_token {
      service_account_email = google_service_account.service_account.email
    }
  }
}