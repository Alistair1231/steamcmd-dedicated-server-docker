FROM steamcmd/steamcmd:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y --no-install-recommends curl sudo libcurl3-gnutls gosu xdg-user-dirs curl jq tzdata lib32gcc-s1 && \
  rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
  chown ubuntu:ubuntu /entrypoint.sh
  

# RUN echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# USER ubuntu
# ENV HOME=/home/ubuntu

WORKDIR /data

STOPSIGNAL SIGINT

ENTRYPOINT ["/entrypoint.sh"]