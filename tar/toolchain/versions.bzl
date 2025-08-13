"""Pre-registered bsdtar binary checksums for each platform

TODO(alexeagle): maybe we should let users pick a different version of bsdtar.
Of course they are free to just register a different toolchain themselves.
"""

BSDTAR_PREBUILT = {
    "darwin_amd64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1-fix.1/tar_darwin_amd64",
        "e8893f7d775d070a333dc386b2aab70dfa43411fcd890222c81212724be7de25",
    ),
    "darwin_arm64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1-fix.1/tar_darwin_arm64",
        "48c1bd214aac26487eaf623d17b77ebce4db3249be851a54edcc940d09d50999",
    ),
    "linux_amd64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1-fix.1/tar_linux_amd64",
        "fff8f72758a52e60fe82beae64b18e7996467013ffe8bec09173d1ba6b66e490",
    ),
    "linux_arm64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1-fix.1/tar_linux_arm64",
        "683468ae45d371e4f392b0e5a524440f6f4507d7da0db60d03ff31f3cf951fc3",
    ),
    "windows_arm64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1-fix.1/tar_windows_arm64.exe",
        "130d69268b0a387bca387d00663821779dd1915557caf7fcbfd5ded3f41074f3",
    ),
    "windows_amd64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1-fix.1/tar_windows_x86_64.exe",
        "f48c81e1812956adb4906c6f057ca856dd280a455e7867d77800e6d5ef9fc81d",
    ),
}
