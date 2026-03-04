# Example include script: changes mode for all file entries to the custom_mode variable.
/type=file/ { sub(/mode=[0-9]+/, "mode=" custom_mode) }
