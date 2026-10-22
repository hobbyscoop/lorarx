#!/usr/bin/env python3
"""Consume exactly the RTL-TCP header, then pipe the IQ bytes to lorarx."""
import subprocess
import socket
import sys

port = int(sys.argv[1])
with socket.create_connection(("127.0.0.1", port), timeout=10) as stream:
    header = bytearray()
    while len(header) < 12:
        chunk = stream.recv(12 - len(header))
        if not chunk:
            raise SystemExit("Proxy disconnected during RTL-TCP header")
        header.extend(chunk)
    if header[:4] != b"RTL0":
        raise SystemExit("Invalid RTL-TCP header")
    stream.settimeout(None)
    with subprocess.Popen(sys.argv[2:], stdin=subprocess.PIPE) as decoder:
        try:
            while chunk := stream.recv(65536):
                decoder.stdin.write(chunk)
                decoder.stdin.flush()
        except BrokenPipeError:
            pass
        finally:
            decoder.stdin.close()
        raise SystemExit(decoder.wait())
