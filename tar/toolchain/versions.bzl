"""Pre-registered bsdtar binary checksums for each platform

TODO(alexeagle): maybe we should let users pick a different version of bsdtar.
Of course they are free to just register a different toolchain themselves.
"""

BSDTAR_PREBUILT = {
    "darwin_amd64": (
        "https://github.com/hermeticbuild/bsdtar-prebuilt/releases/download/v3.8.1-3/tar_darwin_amd64",
        "088ca0f5a655c47fdb3706a599fbd45ab49636bf05eaab3af7df0cafe166168d",
    ),
    "darwin_arm64": (
        "https://github.com/hermeticbuild/bsdtar-prebuilt/releases/download/v3.8.1-3/tar_darwin_arm64",
        "f78ae63e48f58be8e88bb1e44ab165503b8bdc7374cebdeb7fa9327629c88907",
    ),
    "linux_amd64": (
        "https://github.com/hermeticbuild/bsdtar-prebuilt/releases/download/v3.8.1-3/tar_linux_amd64",
        "ae24dbc3ecf6ad628c2fdd205a52347fd4446589e750469766669e25cb80e22b",
    ),
    "linux_arm64": (
        "https://github.com/hermeticbuild/bsdtar-prebuilt/releases/download/v3.8.1-3/tar_linux_arm64",
        "673897c180d9c27770fad1e55914653a6da85fc1f6500df3d768c32916ab8747",
    ),
    "windows_arm64": (
        "https://github.com/hermeticbuild/bsdtar-prebuilt/releases/download/v3.8.1-3/tar_windows_arm64.exe",
        "8a8b94df9bca7ce3f1b47a5bdb507627e4a0dcb8e9d429a37fe37e5aa729208b",
    ),
    "windows_amd64": (
        "https://github.com/hermeticbuild/bsdtar-prebuilt/releases/download/v3.8.1-3/tar_windows_x86_64.exe",
        "550fc86489a24c0774d3cafbe326c1da01f374521154e9f0b9b77332b48e8b46",
    ),
}
