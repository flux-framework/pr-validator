FROM alpine:3.10
RUN apk add --no-cache \
  bash \
  git \
  ncurses
COPY check-pr-commits.sh /check-pr-commits.sh
ENTRYPOINT ["/bin/bash", "/check-pr-commits.sh"]
