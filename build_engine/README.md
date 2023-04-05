This directory contains the build_engine docker image which is then
used by our other cloud build config to actually build the engine.

This is the "base image" which contains all the installed tools, and a
(possibly old) copy of the sources.

It's used by calling the entrypoint (build.sh) with the git-sha you want
to build.