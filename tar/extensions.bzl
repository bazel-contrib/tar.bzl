"Support calls from MODULE.bazel to setup the toolchains"

load("//tar/toolchain:platforms.bzl", "BSDTAR_PLATFORMS", "bsdtar_binary_repo")
load("//tar/toolchain:toolchain.bzl", "tar_toolchains_repo")

def create_repositories(name = "bsd_tar_toolchains"):
    tar_toolchains_repo(name = name, user_repository_name = name)
    for platform in BSDTAR_PLATFORMS.keys():
        bsdtar_binary_repo(name = "{}_{}".format(name, platform), platform = platform)

def _toolchains_extension(mctx):
    create_repositories()
    return mctx.extension_metadata(reproducible = True)

toolchains = module_extension(
    implementation = _toolchains_extension,
)
