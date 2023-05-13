package main

import "core:fmt"
import "core:strings"
import "core:mem"
import "core:net"
import "core:os"

USER_AGENT :: "Odin/9f39209"

Error :: union #shared_nil {
    net.Network_Error,
    mem.Allocator_Error,
}

generate_header :: proc(method, host, path: string, queries: map[string]string) -> string {
    using strings
    b := builder_make()
    write_string(&b, fmt.tprintf("%s %s", method, path))

    query_len := len(queries);
    if query_len > 0 {
        write_string(&b, "?")
        i := 0
        for k, v in queries {
            if i >= query_len - 1 {
                write_string(&b, fmt.tprintf("%s=%s", k, v))
                break
            }
            write_string(&b, fmt.tprintf("%s=%s&", k, v))
            i += 1
        }
    }

    write_string(&b, " HTTP/1.1\r\n")
    write_string(&b, fmt.tprintf("Host: %s\r\n", host))
    write_string(&b, fmt.tprintf("User-Agent: %s\r\n\r\n", USER_AGENT))
    return to_string(b)
}

recv_line_tcp :: proc(socket: net.TCP_Socket) -> (response: string, err: net.Network_Error) {
    using strings
    b := builder_make()
    buf: [1]byte
    for {
        r := net.recv_tcp(socket, buf[:]) or_return
        if r <= 0 {
            return to_string(b), nil
        }
        if buf[0] != '\r' {
            write_bytes(&b, buf[:])
            continue
        }
        r = net.recv_tcp(socket, buf[:]) or_return
        if buf[0] == '\n' {
            return to_string(b), nil
        }
    }
}

handle_header :: proc(socket: net.TCP_Socket) -> (header: [dynamic]string, err: net.Network_Error) {
    for {
        l := recv_line_tcp(socket) or_return
        if len(l) <= 0 {
            return header, nil
        }
        append(&header, l)
    }
}

header_to_map :: proc(list: [dynamic]string) -> (header: map[string]string, err: mem.Allocator_Error) {
    using strings
    for l in list {
        h := split_n(l, ":", 2) or_return
        header[trim_space(h[0])] = trim_space(h[1])
    }
    return header, nil
}

http_get :: proc(host, path: string, queries: map[string]string) -> (err: Error) {
    socket := net.dial_tcp(host, 80) or_return
    rheader := generate_header("GET", host, path, queries)
    bytes := net.send_tcp(socket, transmute([]u8)rheader) or_return
    status := recv_line_tcp(socket) or_return
    raw := handle_header(socket) or_return
    header := header_to_map(raw) or_return
    net.close(socket)
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
