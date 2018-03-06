/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# Master instance    
resource "google_sql_database_instance" "master" {
  name             = "${var.name}"
  project          = "${var.project}"
  region           = "${var.region}"
  database_version = "${var.database_version}"

  settings {
    tier                        = "${var.tier}"
    activation_policy           = "${var.activation_policy}"
    authorized_gae_applications = ["${var.authorized_gae_applications}"]
    disk_autoresize             = "${var.disk_autoresize}"
    ip_configuration            = ["${var.ip_configuration}"]
    location_preference         = ["${var.location_preference}"]
    maintenance_window          = ["${var.maintenance_window}"]
    disk_size                   = "${var.disk_size}"
    disk_type                   = "${var.disk_type}"
    pricing_plan                = "${var.pricing_plan}"
    replication_type            = "${var.replication_type}"

    backup_configuration        = {
      binary_log_enabled = "${var.binary_log_enabled}"
      enabled            = "${var.backup_enabled}"
      start_time         = "${var.backup_start_time}"
    }  
  }
  replica_configuration = ["${var.replica_configuration}"]
}
resource "google_sql_database" "default" {
  name      = "${var.db_name}"
  project   = "${var.project}"
  instance  = "${google_sql_database_instance.master.name}"
  charset   = "${var.db_charset}"
  collation = "${var.db_collation}"
}

resource "random_id" "user-password" {
  byte_length = 32
}
   
resource "random_id" "extension" {
  byte_length = 4
}   

resource "google_sql_user" "proxyuser" {
  name            = "${var.user_name}"
  project         = "${var.project}"
#  password        = "${var.user_password}"
  instance        = "${google_sql_database_instance.master.name}"
  host            = "cloudsqlproxy~%"
  depends_on      = ["google_sql_database_instance.replica"] 
}
   
#resource "google_sql_user" "default" {
#  name       = "${var.user_name}"
#  project    = "${var.project}"
#  instance   = "${google_sql_database_instance.master.name}"
#  host       = "${var.user_host}"
#  password   = "${var.user_password == "" ? random_id.user-password.hex : var.user_password}"
#  depends_on = ["google_sql_database_instance.replica"]  
#}

# Slave instance    
resource "google_sql_database_instance" "replica" {
  name = "${var.name}-replica"
  project              = "${var.project}"
  region               = "${var.region}"
  database_version     = "${var.database_version}"
  master_instance_name = "${google_sql_database_instance.master.name}"

  replica_configuration {
    connect_retry_interval = "${var.connect_retry_interval}"
    failover_target        = "true"
  }

  settings {
    tier                        = "${var.tier}"
    activation_policy           = "${var.activation_policy}"
    authorized_gae_applications = ["${var.authorized_gae_applications}"]
    disk_autoresize             = "${var.disk_autoresize}"
    ip_configuration            = ["${var.ip_configuration}"]
    location_preference         = ["${var.location_preference}"]
    maintenance_window          = ["${var.maintenance_window}"]
    disk_size                   = "${var.disk_size}"
    disk_type                   = "${var.disk_type}"
    pricing_plan                = "${var.pricing_plan}"

    maintenance_window {
      day  = "${var.maintenance_window_day_replica}"
      hour = "${var.maintenance_window_hour_replica}"
    }
  }
}
