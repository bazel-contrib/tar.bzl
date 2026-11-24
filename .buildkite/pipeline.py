#!/usr/bin/env python3
"""Generate Linux Buildkite test jobs using only the Python standard library."""

import json
import shlex


# Keep supported versions and workspace exclusions beside the ruleset changes.
BAZEL_VERSIONS = {
    ".": ("7.x", "8.x", "9.x"),
    "e2e/smoke": ("7.x", "8.x", "9.x"),
    # Bazel 9 is disabled for examples until they support it.
    "examples": ("7.x", "8.x"),
}


def test_step(workspace, version, *, legacy_workspace=False):
    mode = "WORKSPACE" if legacy_workspace else "Bzlmod"
    args = ["bazel", "test", "--config=ci"]
    if legacy_workspace:
        args.append("--noenable_bzlmod")
    args.append("//...")
    return {
        "label": f":bazel: {workspace} / Bazel {version} ({mode})",
        "env": {"USE_BAZEL_VERSION": version},
        "command": f"cd {shlex.quote(workspace)}\n{shlex.join(args)}",
    }


def pipeline():
    steps = [
        test_step(workspace, version)
        for workspace, versions in BAZEL_VERSIONS.items()
        for version in versions
    ]
    # The smoke workspace also exercises legacy WORKSPACE dependency resolution.
    steps.append(test_step("e2e/smoke", "7.x", legacy_workspace=True))
    return {"agents": {"queue": "default"}, "steps": steps}


if __name__ == "__main__":
    print(json.dumps(pipeline(), indent=2))
