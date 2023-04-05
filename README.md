Contains two cloudbuild scripts:
1. cloudbuild.yaml - Used per-revision to build the engine.

```
gcloud builds submit \
  --config cloudbuild.yaml --no-source \
  --substitutions=COMMIT_SHA=79f4c5321a581f580a9bda01ec372cbf4a53aa53
```

2. build_engine/cloudbuild.yaml - builds a "build_engine" base image used by the
   first script to do the actual building.

```
cd build_engine
gcloud builds submit --config cloudbuild.yaml .
```
