FROM alpine:3.22
RUN apk add --no-cache \
  bash \
  git \
  ncurses \
  musl-dev \
  wget \
  findutils \
  jq
RUN wget -qO- https://api.github.com/repos/crate-ci/typos/releases/latest \
  | jq -r '.assets | map(select(.name | match("x86_64-.*-linux.*.tar.gz")))[0] | .browser_download_url' \
  | xargs wget
RUN tar -C/bin -xzf /typos-*.tar.gz ./typos
COPY check-pr-commits.sh /check-pr-commits.sh
ENTRYPOINT ["/bin/bash", "/check-pr-commits.sh"]
