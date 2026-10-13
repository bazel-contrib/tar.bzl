# Issue #133: mtree work on cached builds

Local repro for [bazel-contrib/tar.bzl#133](https://github.com/bazel-contrib/tar.bzl/issues/133).
Uses the current checkout through `local_path_override` and Bazel 9.2.0 through
Bazelisk. Requires Python 3.8+ and Bazel/Bazelisk on `PATH`.

From the repository root:

```sh
python3 e2e/issue_133/repro.py
```

The script generates 90,000 small source files under `data/`, gives them to a
`sh_binary` through `data = glob(["data/**"])`, and packages that binary with
`tar(mtree = "auto", srcs = [":app"])`. Files share deep parent directories to
expose repeated directory-entry construction. These are individual runfiles,
not a tree artifact.

Each run creates a fresh, isolated output base. The first build populates its
disk action cache; two subsequent builds reuse that cache. Every build uses
`--batch`, forcing a fresh in-memory analysis graph so Bazel checks action keys.
A same-server no-op build can skip that work and hide the problem. User and
repository bazelrc files are ignored, so ambient remote caches and execution
settings do not affect the repro. Repository downloads can affect the first
build's wall time; dependencies remain cached for subsequent builds.

The script records JSON trace profiles, Starlark CPU profiles, build-event JSON,
logs, and `summary.json` under `.repro/<timestamp>/`. The summary includes Bazel
phase/CPU timing and memory metrics to distinguish saved work from work moved
into analysis. It prints the time spent in
`action dependency checking` for `Writing file app_tar_mtree.txt` and the number
of executed cacheable actions. Bazel's internal workspace-status action runs
unconditionally and is excluded from that count. Cached builds must execute
zero other actions, including `Tar` and `FileWrite`, and still capture mtree
checking. It also verifies identical mtree/archive SHA-256 hashes across
builds and that the archive contains every generated data file. Wall time
includes JVM startup and loading/analysis; mtree-check time isolates the issue.
There is no machine-dependent timing threshold.

The default size matches the approximate mtree file-entry cardinality reported
in [CI-748](https://linear.app/figma/issue/CI-748/investigate-slow-bazel-dependency-checking-in-fully-cached-master):
83,000 for AI trace analyzer and 87,000 for Sinatra. Those are generated mtree
file entries, which can differ from the number of unique runfiles when multiple
executables or runfiles mappings are packaged. The script records actual mtree
file/directory counts and byte size alongside timings. The original 40,000-file
fixture measured 0.67–0.71 seconds of cached mtree checking on this Mac with
upstream Bazel 9.2.0; that establishes the callback work, but does not explain the
reported CI durations. This fixture isolates one archive without the full CI
graph, concurrent checks, or its machine and JVM conditions. Profile span
duration measures elapsed time; the Starlark CPU profile provides separate CPU
samples for the callbacks.

Before optimization, controlled local results at 90,005 mtree file entries, 2,703 directory entries,
and 15.3 MiB of mtree text (two cached builds per version):

| Bazel | Cached mtree dependency checking |
| --- | --- |
| 9.2.0 | 1.39–1.46 s |
| 9.2.0-figma1 | 1.34–1.46 s |

Both runs executed zero cacheable actions and preserved identical outputs.
The reported CI 9.2 profile times are 20.4 s (AI) and 7.8 s (Sinatra), so
matching file-entry cardinality and the Figma Bazel binary still leaves a gap.
Path lengths/depth, runfiles mappings, concurrent work, hardware, and JVM
conditions remain unmatched; the cause of that gap is not established here.
An offline local 9.3.0 comparison stopped during repository resolution because
its required `apple_support` archive was missing from the cache. No 9.3 timing
conclusion follows from that attempt.

To inspect callback CPU usage with an installed `pprof`:

```sh
pprof -top .repro/<timestamp>/cached-1.starlark.pprof
pprof -list=_expand .repro/<timestamp>/cached-1.starlark.pprof
```

Open `cached-1.profile.json.gz` in a trace viewer and inspect the mtree write
under `action dependency checking`. In the original implementation,
`_mtree_impl` uses `Args.add_all(map_each = ..., uniquify = True)` over runfiles.
`_expand` starts a new `seen_parents` dictionary for each file, so shared parent
entries are repeatedly constructed by `_add_parent_lines` / `_mtree_line` and
only then deduplicated. Fingerprinting the write action expands these arguments
even when its output and the archive are already cached.

The optimized implementation expands each file depset in one callback, sharing
a parent-directory set and output buffer within that expansion. It starts
parent scanning at the last path separator and formats metadata without a list
of temporary attribute strings. It registers tree artifacts separately with
Args so execution-time directory expansion still works; only that registration
walks file metadata during analysis. Mtree text remains deferred.

A subsequent comparison used the original committed module via
`--override_module` and the optimized checkout, both with `9.2.0-figma1`, the
same 90,000 data files, and three cached builds. Cached builds ran sequentially;
ancillary tests completed before those trials. Medians from the saved profiles
and build-event metrics:

| Metric | Original | Optimized |
| --- | --- | --- |
| Mtree dependency checking | 1.310 s | 0.560 s |
| Analysis phase | 1.401 s | 1.432 s |
| Whole Bazel invocation | 4.043 s | 4.041 s |
| Whole Bazel process CPU | 37.388 s | 37.582 s |

Mtree checking improved by about 2.3x (57%), with no measurable whole-build wall
or CPU improvement in this fixture. Process CPU includes all JVM threads.
The mtree and archive remained byte-for-byte identical across implementations,
including entry ordering. All 26 existing tests pass on Bazel 9.0.0 and 9.2.0;
52 existing archive/mtree outputs also match the original implementation's
bytes on 9.2.0, covering source/generated files, tree artifacts, external files,
spaces, runfiles symlinks, mutations, and unused-input pruning.

Comparison artifacts are in `.repro/20261013-164139-126763/` (original) and
`.repro/20261013-164243-663468/` (optimized). These are local gitignored results.

Other sizes, longer sampling, and a different local implementation:

```sh
python3 e2e/issue_133/repro.py --files 50000 --cached-runs 3
python3 e2e/issue_133/repro.py --bazel-arg=--override_module=tar.bzl=/path/to/checkout
USE_BAZEL_VERSION=9.3.0 python3 e2e/issue_133/repro.py
```

Generate only, then build manually:

```sh
python3 e2e/issue_133/repro.py --generate-only
cd e2e/issue_133
bazel build //:app_tar
```

Generated files and results are gitignored. Remove `data/` and `.repro/` from
this directory to clean up. The benchmark stays outside the root `//...` test
suite because `e2e/` is already in `.bazelignore`.
