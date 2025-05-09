load("@aspect_bazel_lib//lib:bats.bzl", "bats_test")

genrule(
    name = "coreutils",
    outs = ["coreutils_bin"],
    cmd = "cp $(COREUTILS_BIN) $@",
    toolchains = ["@coreutils_toolchains//:resolved_toolchain"],
)

bats_test(
    name = "encoding",
    size = "small",
    srcs = ["encoding.bats"],
    data = [
        ":coreutils",
        "//tar/private:unvis.gawk",
        "//tar/private:vis_canonicalize.gawk",
        "//tar/private:vis_escape.gawk",
        "@gawk",
    ],
    env = {
        "GAWK": "$(rootpath @gawk)",
        "VIS_ESCAPE": "$(location //tar/private:vis_escape.gawk)",
        "UNVIS": "$(location //tar/private:unvis.gawk)",
        "VIS_CANONICALIZE": "$(location //tar/private:vis_canonicalize.gawk)",
        "COREUTILS": "$(rootpath :coreutils)",
    },
)
