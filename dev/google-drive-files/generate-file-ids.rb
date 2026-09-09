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
OPENARM_HARDWARE_FOLDER_ID = "14RM-fIPml0HTMnt2zcTXjNxJj9s2R_mG"
# Only files in "v${VERSION}/Hardware/" are included. "v${VERSION}/"
# and "Hardware/" are omitted from the path.
HARDWARE_DIRECTORY = "Hardware"

def output?(name, version)
  return true unless /_v\d+\.\d+_/.match?(name)
  name.include?("_v#{version}_")
end

def folder?(item)
  item.mime_type == "application/vnd.google-apps.folder"
end

def each_item(drive, folder_id)
  return to_enum(__method__, drive, folder_id) unless block_given?

  page_token = nil
  loop do
    response = drive.list_files(
      q: "'#{folder_id}' in parents",
      order_by: "name",
      page_token: page_token
    )
    response.files.each do |item|
      yield(item)
    end
    page_token = response.next_page_token
    break if page_token.nil?
  end
end

def find_folder(drive, folder_id, name)
  each_item(drive, folder_id).find do |item|
    folder?(item) and item.name == name
  end
end

def list_files(drive, folder_id, version, parent_path: "")
  each_item(drive, folder_id) do |item|
    if folder?(item)
      list_files(drive, item.id, version, parent_path: "#{parent_path}#{item.name}/")
    elsif item.mime_type == "application/vnd.google-apps.document"
      # Google Docs can't be downloaded as is. The release job
      # exports it as PDF. The MIME type in the third column tells
      # the release job to do so.
      puts "#{item.id}\t#{parent_path}#{item.name}.pdf\t#{item.mime_type}"
    elsif item.mime_type.start_with?("application/vnd.google-apps.")
      $stderr.puts "Skipped unsupported Google Workspace file: #{parent_path}#{item.name} (#{item.mime_type})"
    elsif output?(item.name, version)
      puts "#{item.id}\t#{parent_path}#{item.name}"
    end
  end
end

# The JSON file for the service account is specified via the environment variable GOOGLE_APPLICATION_CREDENTIALS.
# https://github.com/googleapis/google-auth-library-ruby?tab=readme-ov-file#example-service-account
if ARGV.size != 1
  puts "Usage: #{$0} NEXT_VERSION"
  exit false
end
version = ARGV[0]
drive = Google::Apis::DriveV3::DriveService.new
drive.authorization = Google::Auth::ServiceAccountCredentials.from_env(scope: SCOPES)
version_folder = find_folder(drive, OPENARM_HARDWARE_FOLDER_ID, "v#{version}")
if version_folder.nil?
  $stderr.puts "v#{version}/ doesn't exist"
  exit false
end
hardware_folder = find_folder(drive, version_folder.id, HARDWARE_DIRECTORY)
if hardware_folder.nil?
  $stderr.puts "v#{version}/#{HARDWARE_DIRECTORY}/ doesn't exist"
  exit false
end
list_files(drive, hardware_folder.id, version)
