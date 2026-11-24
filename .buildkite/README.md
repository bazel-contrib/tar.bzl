# Buildkite

`pipeline.py` generates the Linux test pipeline as Buildkite-compatible JSON.
The matrix lives in this repository so changes to supported Bazel versions,
workspaces, and test flags can be reviewed and built with the ruleset changes.

Run locally to inspect the jobs:

```sh
.buildkite/pipeline.py
```

Configure the Buildkite pipeline bootstrap to run this from the checkout root:

```sh
set -euo pipefail
.buildkite/pipeline.py | buildkite-agent pipeline upload
```

The setup agent needs Python 3.8 or newer. Test jobs use the `default` queue and
need Linux agents with Bazelisk and the repository build tools. Each job selects
its Bazel version through `USE_BAZEL_VERSION` and runs `bazel test --config=ci //...`
in its workspace. The smoke workspace also tests legacy WORKSPACE dependency
resolution with Bazel 7.

Update `BAZEL_VERSIONS` and the legacy smoke step in `pipeline.py` when changing
the test matrix. macOS and pre-commit checks are configured in GitHub Actions;
Aspect Workflows configuration lives in `.aspect/workflows/config.yaml`.
