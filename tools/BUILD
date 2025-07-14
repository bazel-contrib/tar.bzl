load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_file")
load("@bazelrc-preset.bzl", "generate_preset")

generate_preset(
    name = "preset",
    out = "_preset.bazelrc",
    strict = True,
)

write_source_file(
    name = "preset.write",
    in_file = "preset",
    out_file = "preset.bazelrc",
    tags = ["manual"],
)
