package main

import "core:fmt"
import "core:strings"
import "core:net"
import "core:os"

USER_AGENT :: "Odin/9f39209"

generate_header :: proc(method, host, path: string, queries: map[string]string) -> string {
    using strings
    b := builder_make()
    write_string(&b, fmt.tprintf("GET %s HTTP/1.1\r\n", path))
    write_string(&b, fmt.tprintf("Host: %s\r\n", host))
    write_string(&b, fmt.tprintf("User-Agent: %s\r\n\r\n", USER_AGENT))
    return to_string(b)
}

http_get :: proc(host, path: string, queries: map[string]string) -> (err: net.Network_Error) {
    header := generate_header("GET", host, path, queries)
    return nil
}

main :: proc() {
    if len(os.args) < 2 {
        return
    }
    url := os.args[1]
    scheme, host, path, queries := net.split_url(url)
    if scheme != "http" {
        return
    }
    err := http_get(host, path, queries)
    if err != nil {
        fmt.println(err)
    }
}
