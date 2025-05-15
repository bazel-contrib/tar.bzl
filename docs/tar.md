<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for calling tar, see https://man.freebsd.org/cgi/man.cgi?tar(1)

<a id="tar_rule"></a>

## tar_rule

<pre>
load("@tar.bzl//tar:tar.bzl", "tar_rule")

tar_rule(<a href="#tar_rule-name">name</a>, <a href="#tar_rule-srcs">srcs</a>, <a href="#tar_rule-out">out</a>, <a href="#tar_rule-args">args</a>, <a href="#tar_rule-compress">compress</a>, <a href="#tar_rule-compute_unused_inputs">compute_unused_inputs</a>, <a href="#tar_rule-mode">mode</a>, <a href="#tar_rule-mtree">mtree</a>)
</pre>

Rule that executes BSD `tar`. Most users should use the [`tar`](#tar) macro, rather than load this directly.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="tar_rule-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="tar_rule-srcs"></a>srcs |  Files, directories, or other targets whose default outputs are placed into the tar.<br><br>If any of the srcs are binaries with runfiles, those are copied into the resulting tar as well.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="tar_rule-out"></a>out |  Resulting tar file to write. If absent, `[name].tar` is written.   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="tar_rule-args"></a>args |  Additional flags permitted by BSD tar; see the man page.   | List of strings | optional |  `[]`  |
| <a id="tar_rule-compress"></a>compress |  Compress the archive file with a supported algorithm.   | String | optional |  `""`  |
| <a id="tar_rule-compute_unused_inputs"></a>compute_unused_inputs |  Whether to discover and prune input files that will not contribute to the archive.<br><br>Unused inputs are discovered by comparing the set of input files in `srcs` to the set of files referenced by `mtree`. Files not used for content by the mtree specification will not be read by the `tar` tool when creating the archive and can be pruned from the input set using the `unused_inputs_list` [mechanism](https://bazel.build/contribute/codebase#input-discovery).<br><br>Benefits: pruning unused input files can reduce the amount of work the build system must perform. Pruned files are not included in the action cache key; changes to them do not invalidate the cache entry, which can lead to higher cache hit rates. Actions do not need to block on the availability of pruned inputs, which can increase the available parallelism of builds. Pruned files do not need to be transferred to remote-execution workers, which can reduce network costs.<br><br>Risks: pruning an actually-used input file can lead to unexpected, incorrect results. The comparison performed between `srcs` and `mtree` is currently inexact and may fail to handle handwritten or externally-derived mtree specifications. However, it is safe to use this feature when the lines found in `mtree` are derived from one or more `mtree_spec` rules, filtered and/or merged on whole-line basis only.<br><br>Possible values:<br><br>    - `compute_unused_inputs = 1`: Always perform unused input discovery and pruning.     - `compute_unused_inputs = 0`: Never discover or prune unused inputs.     - `compute_unused_inputs = -1`: Discovery and pruning of unused inputs is controlled by the         --[no]@tar.bzl//tar:tar_compute_unused_inputs flag.   | Integer | optional |  `-1`  |
| <a id="tar_rule-mode"></a>mode |  A mode indicator from the following list, copied from the tar manpage:<br><br>- create: Create a new archive containing the specified items.<br><br>Other modes may be added in the future.   | String | optional |  `"create"`  |
| <a id="tar_rule-mtree"></a>mtree |  An mtree specification file   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="tar"></a>

## tar

<pre>
load("@tar.bzl//tar:tar.bzl", "tar")

tar(<a href="#tar-name">name</a>, <a href="#tar-mtree">mtree</a>, <a href="#tar-mutate">mutate</a>, <a href="#tar-stamp">stamp</a>, <a href="#tar-kwargs">**kwargs</a>)
</pre>

Wrapper macro around [`tar_rule`](#tar_rule).

### Options for mtree

mtree provides the "specification" or manifest of a tar file.
See https://man.freebsd.org/cgi/man.cgi?mtree(8)
Because BSD tar doesn't have a flag to set modification times to a constant,
we must always supply an mtree input to get reproducible builds.
See https://reproducible-builds.org/docs/archives/ for more explanation.

1. By default, mtree is "auto" which causes the macro to create an `mtree_spec` rule.

2. `mtree` may be supplied as an array literal of lines, e.g.

```
mtree =[
    "usr/bin uid=0 gid=0 mode=0755 type=dir",
    "usr/bin/ls uid=0 gid=0 mode=0755 time=0 type=file content={}/a".format(package_name()),
],
```

For the format of a line, see "There are four types of lines in a specification" on the man page for BSD mtree,
https://man.freebsd.org/cgi/man.cgi?mtree(8)

3. `mtree` may be a label of a file containing the specification lines.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="tar-name"></a>name |  name of resulting `tar_rule`   |  none |
| <a id="tar-mtree"></a>mtree |  "auto", or an array of specification lines, or a label of a file that contains the lines. Subject to [$(location)](https://bazel.build/reference/be/make-variables#predefined_label_variables) and ["Make variable"](https://bazel.build/reference/be/make-variables) substitution.   |  `"auto"` |
| <a id="tar-mutate"></a>mutate |  a partially-applied `mtree_mutate` rule   |  `None` |
| <a id="tar-stamp"></a>stamp |  should mtree attribute be stamped   |  `0` |
| <a id="tar-kwargs"></a>kwargs |  additional named parameters to pass to `tar_rule`   |  none |


<a id="tar_lib.common.add_compression_args"></a>

## tar_lib.common.add_compression_args

<pre>
load("@tar.bzl//tar:tar.bzl", "tar_lib")

tar_lib.common.add_compression_args(<a href="#tar_lib.common.add_compression_args-compress">compress</a>, <a href="#tar_lib.common.add_compression_args-args">args</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="tar_lib.common.add_compression_args-compress"></a>compress |  <p align="center"> - </p>   |  none |
| <a id="tar_lib.common.add_compression_args-args"></a>args |  <p align="center"> - </p>   |  none |


<a id="tar_lib.implementation"></a>

## tar_lib.implementation

<pre>
load("@tar.bzl//tar:tar.bzl", "tar_lib")

tar_lib.implementation(<a href="#tar_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="tar_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


<a id="tar_lib.mtree_implementation"></a>

## tar_lib.mtree_implementation

<pre>
load("@tar.bzl//tar:tar.bzl", "tar_lib")

tar_lib.mtree_implementation(<a href="#tar_lib.mtree_implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="tar_lib.mtree_implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


