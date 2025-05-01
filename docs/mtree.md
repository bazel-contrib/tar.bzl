<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="mtree_spec"></a>

## mtree_spec

<pre>
load("@tar.bzl//tar:mtree.bzl", "mtree_spec")

mtree_spec(<a href="#mtree_spec-name">name</a>, <a href="#mtree_spec-srcs">srcs</a>, <a href="#mtree_spec-out">out</a>, <a href="#mtree_spec-include_runfiles">include_runfiles</a>)
</pre>

Create an mtree specification to map a directory hierarchy. See https://man.freebsd.org/cgi/man.cgi?mtree(8)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="mtree_spec-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="mtree_spec-srcs"></a>srcs |  Files that are placed into the tar   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="mtree_spec-out"></a>out |  Resulting specification file to write   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="mtree_spec-include_runfiles"></a>include_runfiles |  Include the runfiles tree in the resulting mtree for targets that are executable.<br><br>The runfiles are in the paths that Bazel uses. For example, for the target `//my_prog:foo`, we would see files under paths like `foo.runfiles/<repo name>/my_prog/<file>`   | Boolean | optional |  `True`  |


<a id="mtree_mutate"></a>

## mtree_mutate

<pre>
load("@tar.bzl//tar:mtree.bzl", "mtree_mutate")

mtree_mutate(<a href="#mtree_mutate-name">name</a>, <a href="#mtree_mutate-mtree">mtree</a>, <a href="#mtree_mutate-srcs">srcs</a>, <a href="#mtree_mutate-preserve_symlinks">preserve_symlinks</a>, <a href="#mtree_mutate-strip_prefix">strip_prefix</a>, <a href="#mtree_mutate-package_dir">package_dir</a>, <a href="#mtree_mutate-mtime">mtime</a>, <a href="#mtree_mutate-owner">owner</a>,
             <a href="#mtree_mutate-ownername">ownername</a>, <a href="#mtree_mutate-awk_script">awk_script</a>, <a href="#mtree_mutate-kwargs">**kwargs</a>)
</pre>

Modify metadata in an mtree file.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="mtree_mutate-name"></a>name |  name of the target, output will be `[name].mtree`.   |  none |
| <a id="mtree_mutate-mtree"></a>mtree |  input mtree file, typically created by `mtree_spec`.   |  none |
| <a id="mtree_mutate-srcs"></a>srcs |  list of files to resolve symlinks for.   |  `None` |
| <a id="mtree_mutate-preserve_symlinks"></a>preserve_symlinks |  `EXPERIMENTAL!` We may remove or change it at any point without further notice. Flag to determine whether to preserve symlinks in the tar.   |  `False` |
| <a id="mtree_mutate-strip_prefix"></a>strip_prefix |  prefix to remove from all paths in the tar. Files and directories not under this prefix are dropped.   |  `None` |
| <a id="mtree_mutate-package_dir"></a>package_dir |  directory prefix to add to all paths in the tar.   |  `None` |
| <a id="mtree_mutate-mtime"></a>mtime |  new modification time for all entries.   |  `None` |
| <a id="mtree_mutate-owner"></a>owner |  new uid for all entries.   |  `None` |
| <a id="mtree_mutate-ownername"></a>ownername |  new uname for all entries.   |  `None` |
| <a id="mtree_mutate-awk_script"></a>awk_script |  may be overridden to change the script containing the modification logic.   |  `Label("@tar.bzl//tar/private:modify_mtree.awk")` |
| <a id="mtree_mutate-kwargs"></a>kwargs |  additional named parameters to genrule   |  none |


