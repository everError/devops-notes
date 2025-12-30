```
(common_handlers) {
    handle /[]* {
        root * C:/app/html
        try_files {path} {path}/ /[]/index.html
        file_server
    }
    handle /pop* {
        root * C:/app/html
        try_files {path} {path}/ /[]/index.html
        file_server
    }
    handle /[]/* {
        reverse_proxy []-service:80 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            transport http {
                dial_timeout 3600s
                response_header_timeout 3600s
            }
        }
    }
    handle /[]* {
        reverse_proxy []-service:80 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            transport http {
                dial_timeout 3600s
                response_header_timeout 3600s
            }
        }
    }
    handle /[]* {
        reverse_proxy []-service:80 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            transport http {
                dial_timeout 3600s
                response_header_timeout 3600s
            }
        }
    }
    handle /ws* {
        reverse_proxy []-service:80 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
            transport http {
                read_timeout 86400s
                write_timeout 86400s
            }
        }
    }
}

:443 {
    tls C:/app/certs/[].pem C:/app/certs/[].key
    request_body {
        max_size 0
    }
    import common_handlers
}

:80 {
    request_body {
        max_size 0
    }
    import common_handlers
}
```
