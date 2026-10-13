#!/usr/bin/env python3
"""Profile cold and disk-cached tar builds with many individual runfiles."""

import argparse
from datetime import datetime
import gzip
import hashlib
import json
from pathlib import Path
import shlex
import shutil
import subprocess
import tarfile
import time


ROOT = Path(__file__).resolve().parent


def positive_int(value):
    value = int(value)
    if value < 1:
        raise argparse.ArgumentTypeError("must be positive")
    return value


def generate(count):
    data = ROOT / "data"
    # Delete only this repro's generated fixture when the requested size changes.
    marker = ROOT / ".repro" / "file-count.txt"
    if marker.exists() and marker.read_text().strip() == str(count):
        if sum(1 for _ in data.rglob("*.txt")) == count:
            return
    if data.exists():
        shutil.rmtree(data)
    for index in range(count):
        # Many files share a deep parent path, exposing repeated parent entries.
        directory = data / ("group_%04d" % (index // 100)) / "shared" / "nested"
        directory.mkdir(parents=True, exist_ok=True)
        (directory / ("file_%06d.txt" % index)).write_text("%d\n" % index)
    marker.parent.mkdir(parents=True, exist_ok=True)
    marker.write_text("%d\n" % count)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def summarize(run, name, wall_seconds):
    with gzip.open(run / (name + ".profile.json.gz"), "rt") as stream:
        events = json.load(stream)["traceEvents"]
    checks = [
        event for event in events
        if event.get("cat") == "action dependency checking"
        and "app_tar_mtree.txt" in event.get("name", "")
    ]
    writes = [
        event for event in events
        if event.get("cat") == "action processing"
        and "app_tar_mtree.txt" in event.get("name", "")
    ]
    mtree = ROOT / ".repro" / "bazel-bin" / "app_tar_mtree.txt"
    with mtree.open() as stream:
        file_entries = directory_entries = 0
        for line in stream:
            file_entries += " type=file " in line
            directory_entries += " type=dir " in line
    metrics = None
    with (run / (name + ".bep.json")).open() as stream:
        for line in stream:
            event = json.loads(line)
            if "buildMetrics" in event:
                metrics = event["buildMetrics"]
    if metrics is None:
        raise RuntimeError("missing BuildMetrics in " + name)
    actions = metrics.get("actionSummary", {})
    executed = int(actions.get("actionsExecuted", 0))
    workspace_status = sum(
        int(action.get("actionsExecuted", 0))
        for action in actions.get("actionData", [])
        if action.get("mnemonic") == "BazelWorkspaceStatusAction"
    )
    return {
        "name": name,
        "wall_seconds": wall_seconds,
        "mtree_check_seconds": sum(event.get("dur", 0) for event in checks) / 1e6,
        "mtree_write_seconds": sum(event.get("dur", 0) for event in writes) / 1e6,
        "mtree_check_events": len(checks),
        "mtree_file_entries": file_entries,
        "mtree_directory_entries": directory_entries,
        "mtree_bytes": mtree.stat().st_size,
        "actions_executed": executed,
        "workspace_status_actions_executed": workspace_status,
        "cacheable_actions_executed": executed - workspace_status,
        "action_cache": actions.get("actionCacheStatistics", {}),
        "action_data": actions.get("actionData", []),
        "timing_metrics": metrics.get("timingMetrics", {}),
        "memory_metrics": metrics.get("memoryMetrics", {}),
        "mtree_sha256": sha256(mtree),
        "archive_sha256": sha256(ROOT / ".repro" / "bazel-bin" / "app.tar"),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--files", type=positive_int, default=90000)
    parser.add_argument("--cached-runs", type=positive_int, default=2)
    parser.add_argument("--bazel", default="bazel", help="Bazel or Bazelisk executable")
    parser.add_argument("--bazel-arg", action="append", default=[], help="extra build flag; use --bazel-arg=--flag=value")
    parser.add_argument("--generate-only", action="store_true")
    args = parser.parse_args()

    generate(args.files)
    print("Fixture: %d individual data files" % args.files, flush=True)
    if args.generate_only:
        return

    run = ROOT / ".repro" / datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    run.mkdir(parents=True)
    # Each invocation gets a fresh in-memory graph. All builds in this run share
    # one output base, so only the first build has an empty disk action cache.
    startup = [
        args.bazel,
        "--batch",
        "--ignore_all_rc_files",
        "--output_user_root=" + str(ROOT / ".repro" / "bazel"),
        "--output_base=" + str(run / "output-base"),
    ]
    version = subprocess.check_output([args.bazel, "--version"], cwd=ROOT, text=True).strip()
    print(version, flush=True)
    results = []
    for name in ["cold"] + ["cached-%d" % n for n in range(1, args.cached_runs + 1)]:
        command = startup + [
            "build",
            "//:app_tar",
            "--color=no",
            "--curses=no",
            "--nobuild_runfile_links",
            "--symlink_prefix=.repro/bazel-",
            "--profile=" + str(run / (name + ".profile.json.gz")),
            "--noslim_profile",
            "--experimental_profile_additional_tasks=action_check",
            "--starlark_cpu_profile=" + str(run / (name + ".starlark.pprof")),
            "--build_event_json_file=" + str(run / (name + ".bep.json")),
        ] + args.bazel_arg
        print("\n" + shlex.join(command), flush=True)
        started = time.monotonic()
        with (run / (name + ".log")).open("w") as log:
            process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            for line in process.stdout:
                print(line, end="", flush=True)
                log.write(line)
            if process.wait():
                raise RuntimeError("build failed; see " + str(run / (name + ".log")))
        result = summarize(run, name, time.monotonic() - started)
        results.append(result)
        (run / "summary.json").write_text(json.dumps({"bazel": version, "files": args.files, "builds": results}, indent=2) + "\n")

    baseline = results[0]
    for result in results[1:]:
        if result["archive_sha256"] != baseline["archive_sha256"] or result["mtree_sha256"] != baseline["mtree_sha256"]:
            raise RuntimeError("mtree/archive changed between cold and cached builds")
        # Bazel runs its workspace-status action unconditionally, including on
        # cache hits. Require every other action (including Tar/FileWrite) cached.
        if result["cacheable_actions_executed"]:
            raise RuntimeError("cached build executed cacheable actions; see its BEP and log")
        if not result["mtree_check_events"]:
            raise RuntimeError("cached profile did not capture mtree action checking")
    with tarfile.open(ROOT / ".repro" / "bazel-bin" / "app.tar") as archive:
        count = sum(1 for member in archive if member.isfile() and member.name.startswith("app.runfiles/_main/data/"))
    if count != args.files:
        raise RuntimeError("expected %d archived data files, got %d" % (args.files, count))

    print("\nBuild          Wall (s)   Mtree cache check (s)   Cacheable actions executed")
    for result in results:
        print("%-12s %10.3f %23.3f %26d" % (result["name"], result["wall_seconds"], result["mtree_check_seconds"], result["cacheable_actions_executed"]))
    print("Identical mtree/archive hashes; all %d data files archived." % count)
    print("Mtree: %d file entries, %d directory entries, %.1f MiB." % (
        baseline["mtree_file_entries"], baseline["mtree_directory_entries"], baseline["mtree_bytes"] / 1024**2,
    ))
    print("Profiles, logs, BEP, and summary: " + str(run))


if __name__ == "__main__":
    main()
