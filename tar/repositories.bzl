"WORKSPACE macros for loading dependencies"

load("@aspect_bazel_lib//lib:utils.bzl", http_archive = "maybe_http_archive")

def tar_dependencies():
    "Load dependencies required by tar rules"

    http_archive(
        name = "gawk",
        urls = [
            "https://ftp.gnu.org/gnu/gawk/gawk-5.3.2.tar.xz",
        ],
        strip_prefix = "gawk-5.3.2",
        integrity = "sha256-+MNIZQnecFGSE4sA7ywAu73Q6Eww1cB9I/xzqdxMycw=",
        build_file_content = "",
        remote_file_urls = {
            "BUILD.bazel": ["https://raw.githubusercontent.com/bazelbuild/bazel-central-registry/refs/heads/main/modules/gawk/5.3.2.bcr.1/overlay/BUILD.bazel"],
            "posix/config_darwin.h": ["https://raw.githubusercontent.com/bazelbuild/bazel-central-registry/refs/heads/main/modules/gawk/5.3.2.bcr.1/overlay/posix/config_darwin.h"],
            "posix/config_linux.h": ["https://raw.githubusercontent.com/bazelbuild/bazel-central-registry/refs/heads/main/modules/gawk/5.3.2.bcr.1/overlay/posix/config_linux.h"],
            "test/BUILD.bazel": ["https://raw.githubusercontent.com/bazelbuild/bazel-central-registry/refs/heads/main/modules/gawk/5.3.2.bcr.1/overlay/test/BUILD.bazel"],
        },
        remote_file_integrity = {
            "BUILD.bazel": "sha256-dt89+9IJ3UzQvoKzyXOiBoF6ok/4u4G0cb0Ja+plFy0=",
            "posix/config_darwin.h": "sha256-gPVRlvtdXPw4Ikwd5S89wPPw5AaiB2HTHa1KOtj40mU=",
            "posix/config_linux.h": "sha256-iEaeXYBUCvprsIEEi5ipwqt0JV8d73+rLgoBYTegC6Q=",
            "test/BUILD.bazel": "sha256-NktOb/GQZ8AimXwLEfGFMJB3TtgAFhobM5f9aWsHwLQ=",
        },
    )
