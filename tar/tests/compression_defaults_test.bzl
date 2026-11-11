"""Tests for workspace-wide compression defaults."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _check_impl(ctx):
    env = analysistest.begin(ctx)
    files = analysistest.target_under_test(env)[DefaultInfo].files.to_list()
    asserts.equals(env, 1, len(files))
    asserts.true(env, files[0].basename.endswith(ctx.attr.expected_suffix))
    return analysistest.end(env)

def _make_test(settings):
    return analysistest.make(
        _check_impl,
        attrs = {"expected_suffix": attr.string(mandatory = True)},
        config_settings = settings,
    )

auto_fast_test = _make_test({"//command_line_option:compilation_mode": "fastbuild"})
auto_opt_test = _make_test({"//command_line_option:compilation_mode": "opt"})
zstd_opt_test = _make_test({"//command_line_option:compilation_mode": "opt", str(Label("//tar:default_compression")): "zstd"})
zstd_fast_test = _make_test({"//command_line_option:compilation_mode": "fastbuild", str(Label("//tar:default_compression")): "zstd"})
none_opt_test = _make_test({"//command_line_option:compilation_mode": "opt", str(Label("//tar:default_compression")): "none"})
