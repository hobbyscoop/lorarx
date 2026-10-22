# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS build
ARG TARGETARCH
ARG LORARX_REV=a291ac481b86097735108525765edc528e97a23f
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git make gcc libc6-dev gcc-aarch64-linux-gnu \
    libc6-dev-arm64-cross python3 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git init . && git remote add origin https://github.com/hsmade/dxlAPRS.git \
    && git fetch --depth=1 origin "$LORARX_REV" && git checkout --detach FETCH_HEAD
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) compiler=gcc; strip=strip ;; \
      arm64) compiler=aarch64-linux-gnu-gcc; strip=aarch64-linux-gnu-strip ;; \
      *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    make -C src OUT=/out/ prepare; \
    make -C src OUT=/out/ CC="$compiler" STRIP="$strip" \
      LFLAGS='-static -Wl,--gc-sections' /out/lorarx /out/udpgate4; \
    if [ "$TARGETARCH" = amd64 ]; then \
      python3 tests/test_lorarx_offset.py /out/lorarx; \
    fi

FROM python:3.13-slim-bookworm
ARG LORARX_REV=a291ac481b86097735108525765edc528e97a23f
LABEL org.opencontainers.image.title="Patched LoRa APRS decoder" \
      org.opencontainers.image.description="dxlAPRS lorarx with the FIR buffer-boundary frequency-shifter fix (upstream PR 45)" \
      org.opencontainers.image.source="https://github.com/hobbyscoop/lorarx" \
      org.opencontainers.image.url="https://github.com/oe5hpm/dxlAPRS/pull/45" \
      org.opencontainers.image.revision="$LORARX_REV" \
      org.opencontainers.image.licenses="GPL-2.0-or-later"
COPY --from=build /out/lorarx /out/udpgate4 /usr/local/bin/
COPY --from=build /src/Licenses /usr/share/licenses/dxlAPRS/
COPY lora-aprs-proxy.py /usr/local/bin/lora-aprs-proxy
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/lorarx"]
CMD ["-h"]
