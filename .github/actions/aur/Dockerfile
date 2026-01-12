FROM docker.io/library/archlinux:base-devel AS base

RUN pacman -Syu --needed --noconfirm pacman-contrib namcap git sudo openssh rsync && \
    echo PKGEXT=.pkg.tar >> /etc/makepkg.conf

FROM base AS yay

RUN useradd -m builder && \
  echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
USER builder
RUN env -C /home/builder git clone https://aur.archlinux.org/yay-bin.git && \
    env -C /home/builder/yay-bin makepkg -s && rm -f /home/builder/yay-bin/yay-bin-debug*.pkg.tar

FROM base

COPY --from=yay /home/builder/yay-bin/yay-*.pkg.tar /tmp/yay.pkg.tar
RUN pacman -U --noconfirm /tmp/yay.pkg.tar && rm -f /tmp/yay.pkg.tar
COPY entrypoint.sh /entrypoint.sh
COPY build.sh /build.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/build.sh" ]
