{
    if ($0 ~ /(^|[[:space:]])type=file([[:space:]]|$)/) {
        if ($0 !~ /(^|[[:space:]])uid=[^[:space:]]+/) {
            $0 = $0 " uid=0"
        }
        if ($0 !~ /(^|[[:space:]])gid=[^[:space:]]+/) {
            $0 = $0 " gid=0"
        }
        if ($0 !~ /(^|[[:space:]])time=[^[:space:]]+/) {
            $0 = $0 " time=1672560000"
        }
        if ($0 !~ /(^|[[:space:]])mode=[^[:space:]]+/) {
            $0 = $0 " mode=0755"
        }
    }
}
