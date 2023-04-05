Contains two cloudbuild scripts:
1. cloudbuild.yaml - Used per-revision to build the engine.

```
gcloud builds submit \
  --config cloudbuild.yaml --no-source \
  --subsitutions=COMMIT_SHA=...
```

2. build_engine/cloudbuild.yaml - builds a "build_engine" base image used by the
   first script to do the actual building.

```
cd build_engine
gcloud builds submit --config cloudbuild.yaml .
```
