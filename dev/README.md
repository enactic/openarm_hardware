# Development

## How to release

1. Update `dev/google-drive-files/file-ids.tsv` to the latest
   Google Drive contents and merge it to `main`. See
   [`dev/google-drive-files/README.md`](google-drive-files/README.md)
   for details.

   The release job downloads only the files listed in
   `file-ids.tsv`. If a file in Google Drive is moved, replaced or
   deleted, its old ID stops working and the release job fails.

2. Tag and push:

   ```bash
   git clone git@github.com:enactic/openarm_hardware.git
   cd openarm_hardware
   dev/release.sh ${VERSION} # e.g. dev/release.sh 1.0.0
   ```
