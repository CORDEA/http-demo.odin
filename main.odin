package main

import "core:fmt"
import "core:strings"
import "core:net"
import "core:os"

USER_AGENT :: "Odin/9f39209"

generate_header :: proc(method, host, path: string, queries: map[string]string) -> string {
    using strings
    b := builder_make()
    write_string(&b, fmt.tprintf("GET %s", path))

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
        r: int
        if r, err = net.recv_tcp(socket, buf[:]); err != nil {
            return "", err
        }
        if r <= 0 {
            return to_string(b), nil
        }
        if buf[0] != '\r' {
            write_bytes(&b, buf[:])
            continue
        }
        if r, err = net.recv_tcp(socket, buf[:]); err != nil {
            return "", err
        }
        if buf[0] == '\n' {
            return to_string(b), nil
        }
    }
}

handle_response :: proc(socket: net.TCP_Socket) -> (response: string, err: net.Network_Error) {
    using strings
    b := builder_make()
    for {
        l: string
        if l, err = recv_line_tcp(socket); err != nil {
            return to_string(b), err
        }
        if len(l) <= 0 {
        }
        write_string(&b, l)
    }
    return to_string(b), nil
}

http_get :: proc(host, path: string, queries: map[string]string) -> (err: net.Network_Error) {
    socket: net.TCP_Socket
    if socket, err = net.dial_tcp(host, 80); err != nil {
        return err
    }
    header := generate_header("GET", host, path, queries)
    bytes: int
    if bytes, err = net.send_tcp(socket, transmute([]u8)header); err != nil {
        return err
    }
    response: string
    if response, err = handle_response(socket); err != nil {
        return err
    }
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
