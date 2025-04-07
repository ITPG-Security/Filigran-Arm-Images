# OpenCTI-Connectors-Arm
This repo is for building all addons of opencti & openbas that do not have ARM64 packages. No clue why they didn't do it.

## Usage
1. Fork this repo.
2. Create a var for the username of docker hub
3. Create a secret with the token for docker hub
4. Go to Actions and perform a build action.
5. Fill in the appropriate details and let it build.

## Problems
GitHub has a limit on the amount of time an action can take (6 hours). To get around this you can eighter configure the max & skip build options, or use your own agent.