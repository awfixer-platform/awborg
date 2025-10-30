# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

# docker.io/library/busybox:1.36.0
# When pinning use the multi-arch manifest list, `docker buildx imagetools inspect ...`
FROM docker.io/library/busybox@sha256:e3652a00a2fabd16ce889f0aa32c38eec347b997e73bd09e69c962ec7f8732ee as release

ARG PRODUCT_NAME=nomad
ARG PRODUCT_VERSION
ARG PRODUCT_REVISION
# TARGETARCH and TARGETOS are set automatically when --platform is provided.
ARG TARGETOS TARGETARCH

LABEL maintainer="Nomad Team <nomad@hashicorp.com>" \
      version=${PRODUCT_VERSION} \
      revision=${PRODUCT_REVISION} \
      org.opencontainers.image.title="nomad" \
      org.opencontainers.image.description="Nomad is a lightweight and flexible orchestrator for heterogenous workloads" \
      org.opencontainers.image.authors="Nomad Team <nomad@hashicorp.com>" \
      org.opencontainers.image.url="https://www.nomadproject.io/" \
      org.opencontainers.image.documentation="https://www.nomadproject.io/docs" \
      org.opencontainers.image.source="https://github.com/hashicorp/nomad" \
      org.opencontainers.image.version=${PRODUCT_VERSION} \
      org.opencontainers.image.revision=${PRODUCT_REVISION} \
      org.opencontainers.image.vendor="HashiCorp" \
      org.opencontainers.image.licenses="BUSL-1.1"

RUN mkdir -p /usr/share/doc/nomad
COPY LICENSE /usr/share/doc/nomad/LICENSE.txt

COPY dist/$TARGETOS/$TARGETARCH/nomad /bin/
COPY ./scripts/docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["help"]
