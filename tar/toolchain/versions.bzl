"""Pre-registered bsdtar binary checksums for each platform

TODO(alexeagle): maybe we should let users pick a different version of bsdtar.
Of course they are free to just register a different toolchain themselves.
"""

BSDTAR_PREBUILT = {
    "darwin_amd64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1/tar_darwin_amd64",
        "921118f1d043aff08a8d7d7b477217781efb9dacad111646add724bc51575c6a",
    ),
    "darwin_arm64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1/tar_darwin_arm64",
        "9e78a0b3e21bc05c67e54004e5b29c2b19c3a9f16ccec4de2a227b1e01aea5fd",
    ),
    "linux_amd64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1/tar_linux_amd64",
        "a703af6fc8df1a89f1ca864c651a9003b75069dd6b80bd32dcd94a7d255df07d",
    ),
    "linux_arm64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1/tar_linux_arm64",
        "663f498baab2a9b7758e46d0c377b311c5b058758a37958372a0503c5dda4028",
    ),
    "windows_arm64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1/tar_windows_arm64.exe",
        "1cb490a72385a394bc3643d8409717c544b7af11a24864dc7bf15f1f7333da22",
    ),
    "windows_amd64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1/tar_windows_x86_64.exe",
        "a548b165eea72e8b8b260b15f9f77625423a8f40c4e436dc235ad9e575b285e2",
    ),
}
