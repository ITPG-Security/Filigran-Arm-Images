# OpenCTI-Connectors-Arm
This repo is for building all addons of opencti & openbas that do not have ARM64 packages. No clue why they didn't do it.

## Usage
To use this all you need to to is clone it and run the build_images.sh with the following params:
```
./build_images.sh <base_dir> <tag_prefix> <builder_name> <opencti_version> <openbas_version> <max_buids> <skip_builds>
```
* `<base_dir>`: base directory. In this case the main directory of the repo
* `<tag_prefix>`: what comes before the `/` in a tag
* `<builder_name>`: the name of the buildx builder
* `<opencti_version>`: version of OpenCTI
* `<openbas_version>`: version of OpenBAS
* `<max_buids>`: Maximum builds to do. Usefull to not go over 6 hour limit for normal agent actions.
* `<skip_builds>`: Builds to skip. Usefull to not go over 6 hour limit for normal agent actions.
