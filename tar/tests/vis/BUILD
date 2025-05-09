load("@aspect_bazel_lib//lib:bats.bzl", "bats_test")

genrule(
  name = "coreutils",
  toolchains = ["@coreutils_toolchains//:resolved_toolchain"],
  outs = ["coreutils_bin"],
  cmd = "cp $(COREUTILS_BIN) $@",
)

bats_test(
  name = "encoding",
  srcs = ["encoding.bats"],
  size = "small",
  data = [
    "//tar/private:vis_escape.gawk",
    "//tar/private:unvis.gawk",
    "//tar/private:vis_canonicalize.gawk",
    ":coreutils",
    "@gawk",
  ],
  env = {
    "GAWK": "$(rootpath @gawk)",
    "VIS_ESCAPE": "$(location //tar/private:vis_escape.gawk)",
    "UNVIS": "$(location //tar/private:unvis.gawk)",
    "VIS_CANONICALIZE": "$(location //tar/private:vis_canonicalize.gawk)",
    "COREUTILS": "$(rootpath :coreutils)",
  }
)
