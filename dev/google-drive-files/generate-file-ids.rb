#!/usr/bin/env ruby
#
# Copyright 2025 Enactic, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "google/apis/drive_v3"

SCOPES = ["https://www.googleapis.com/auth/drive.readonly"]
OPENARM_HARDWARE_FOLDER_ID = "1a9ec9vzBV_D-AX9s_LOkBVy3ZXDC1kJT"

def list_files(drive, folder_id, parent_path: "", page_token: nil)
  response = drive.list_files(
    q: "'#{folder_id}' in parents",
    page_token: page_token
  )
  if response.next_page_token
    list_files(
      dirve,
      folder_id,
      parent_path: parent_path,
      page_token: response.next_page_token
    )
  end

  response.files.each do |item|
    if item.mime_type == "application/vnd.google-apps.folder"
      list_files(drive, item.id, parent_path: "#{parent_path}#{item.name}/")
    else
      puts "#{item.id}\t#{parent_path}#{item.name}"
    end
  end
end

# The JSON file for the service account is specified via the environment variable GOOGLE_APPLICATION_CREDENTIALS.
# https://github.com/googleapis/google-auth-library-ruby?tab=readme-ov-file#example-service-account
drive = Google::Apis::DriveV3::DriveService.new
drive.authorization = Google::Auth::ServiceAccountCredentials.from_env(scope: SCOPES)
list_files(drive, OPENARM_HARDWARE_FOLDER_ID)
