package main

import "core:fmt"
import "core:net"
import "core:os"

main :: proc() {
    if len(os.args) < 2 {
        return
    }
    url := os.args[1]
    scheme, host, path, queries := net.split_url(url)
    if scheme != "http" {
        return
    }
}
