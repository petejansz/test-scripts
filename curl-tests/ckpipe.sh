#! /bin/sh
# Test for stdin, read stdin

stdin="$(ls -l /proc/self/fd/0)"
stdin="${stdin/*-> /}"

if [[ "$stdin" =~ ^/dev/pt.* ]]; then
    echo "Terminal, nothing on stdin"
else
    # $stdin points to a file or pipe_id:
    # Read lines from stdin:
    while read line; do
        echo "$line"
    done
fi

