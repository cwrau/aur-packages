FROM docker.io/library/archlinux:base-devel AS base

RUN pacman -Syu --needed --noconfirm pacman-contrib namcap git sudo

RUN useradd -m builder && \
  echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /home/builder
USER builder

FROM base AS paru

# Install paru
RUN git clone https://aur.archlinux.org/paru-bin.git
WORKDIR /home/builder/paru-bin
RUN makepkg -s OPTIONS=-debug

FROM base

COPY --from=paru /home/builder/paru-bin/paru-*.pkg.tar.zst /tmp/paru.pkg.tar.zst
RUN sudo pacman -U --noconfirm /tmp/paru.pkg.tar.zst && rm -f /tmp/paru.pkg.tar.zst
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
