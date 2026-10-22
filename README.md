# Patched LoRa APRS container

Image: `ghcr.io/hobbyscoop/lorarx:offset-buffer-fix`
Immutable source tag: `ghcr.io/hobbyscoop/lorarx:a291ac4`
Platforms: `linux/amd64`, `linux/arm64`.

Source revision: `a291ac481b86097735108525765edc528e97a23f` in
https://github.com/hsmade/dxlAPRS (upstream PR https://github.com/oe5hpm/dxlAPRS/pull/45).

Includes patched `lorarx`, `udpgate4`, and the Python RTL-proxy input adapter.
Binaries are compiled for each architecture. The synthetic offset regression
runs on amd64 during the build. The image runs as UID/GID 65532 by default.

## Decode a raw IQ recording

```sh
docker run --rm -i ghcr.io/hobbyscoop/lorarx:offset-buffer-fix \
  -i /dev/stdin -f u8 -r 2400000 -o 1075000 -b 7 -s 12 -v -Q -N \
  < capture.u8
```

## Read the shared RTL proxy

On the receiver host (Linux), for center 432.7 MHz, channel 433.775 MHz:

```sh
docker run --rm --network host \
  --entrypoint /usr/local/bin/lora-aprs-proxy \
  ghcr.io/hobbyscoop/lorarx:offset-buffer-fix \
  6000 /usr/local/bin/lorarx \
  -i /dev/stdin -f u8 -r 2400000 -o 1075000 -b 7 -s 12 -v -Q -N
```

The adapter consumes the 12-byte RTL-TCP header before forwarding IQ. To feed
an existing AXUDPv2 iGate, append `-L 127.0.0.1:2310`. Offline replay should
omit forwarding options to avoid gating recorded packets again.

`udpgate4` can be selected with `--entrypoint /usr/local/bin/udpgate4`.
No credentials are embedded in this image.

## Rebuild and publish

```sh
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/hobbyscoop/lorarx:offset-buffer-fix \
  -t ghcr.io/hobbyscoop/lorarx:a291ac4 --push .
```

The Dockerfile's compiler stage runs on an amd64 build host and cross-compiles
the arm64 binary; no ARM emulation is needed for the build.
