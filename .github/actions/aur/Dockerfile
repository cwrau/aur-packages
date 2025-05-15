FROM docker.io/library/archlinux:base-devel AS base

RUN pacman -Syu --needed --noconfirm pacman-contrib namcap git sudo openssh rsync

FROM base AS paru

RUN useradd -m builder && \
  echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
  chown builder:builder /home/builder
USER builder
RUN env -C /home/builder git clone https://aur.archlinux.org/paru-bin.git && \
    env -C /home/builder/paru-bin makepkg -s OPTIONS=-debug

FROM base

COPY --from=paru /home/builder/paru-bin/paru-*.pkg.tar.zst /tmp/paru.pkg.tar.zst
RUN pacman -U --noconfirm /tmp/paru.pkg.tar.zst && rm -f /tmp/paru.pkg.tar.zst
COPY entrypoint.sh /entrypoint.sh
COPY build.sh /build.sh

ENTRYPOINT [ "/entrypoint.sh" ]
