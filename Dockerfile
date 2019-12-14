FROM ubuntu:18.04

ARG xrdp_source=https://github.com/neutrinolabs/xrdp/releases/download/v0.9.11/xrdp-0.9.11.tar.gz
ARG xorgxrdp_source=https://github.com/neutrinolabs/xorgxrdp/releases/download/v0.2.12/xorgxrdp-0.2.12.tar.gz

# install packages
RUN apt-get update \
    && apt-get install --yes --force-yes --no-install-recommends \
        software-properties-common \
        xorg \
        xserver-xorg \
        xfce4 \
        gnome-themes-standard \
        gtk2-engines-pixbuf \
        file-roller \
        evince \
        gpicview \
        leafpad \
        xfce4-whiskermenu-plugin xfce4-xkb-plugin xfce4-terminal \
        xfce4-panel xfce4-session xfce4-appmenu-plugin \
        xfce4-datetime-plugin xfce4-goodies xfce4-notes \
        xfce4-places-plugin xfce4-clipman xfce4-settings \
        ttf-ubuntu-font-family \
        firefox firefox-locale-hu \
        dbus-x11 \
        vnc4server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# build and install xrdp from source in one step (minimise size of container)
RUN apt-get update \
    && apt-get install --yes --force-yes --no-install-recommends \
        wget \
        build-essential \
        libssl-dev \
        libpam0g-dev \
        libxrandr-dev \
        nasm \
        xserver-xorg-dev \
        libxfont-dev \
        pkg-config \
        file \
        libxfixes-dev \
    && cd /tmp \
    && wget --no-check-certificate $xrdp_source \
    && tar -xf xrdp-*.tar.gz -C /tmp/ \
    && cd /tmp/xrdp-* \
    && ./configure \
    && make \
    && make install \
    && cd /tmp \
    && rm -rf xrdp-* \
    && wget --no-check-certificate $xorgxrdp_source \
    && tar -xf xorgxrdp-*.tar.gz -C /tmp/ \
    && cd /tmp/xorgxrdp-* \
    && ./configure \
    && make \
    && make install \
    && cd /tmp \
    && rm -rf xorgxrdp-* \
    && apt-get remove --yes --force-yes \
        build-essential \
        libssl-dev \
        libpam0g-dev \
        libxrandr-dev \
        nasm \
        xserver-xorg-dev \
        libxfont-dev \
        pkg-config \
        file \
        libxfixes-dev \
    && apt-get --yes autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install theme
RUN add-apt-repository ppa:numix/ppa \
    && apt-get update \
    && apt-get install --yes --force-yes --no-install-recommends numix-icon-theme numix-icon-theme-circle \
    fonts-liberation libappindicator3-1 libasound2 libxss1 xdg-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install Chrome
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    dpkg -i google-chrome-stable_current_amd64.deb; apt-get -fy install

# add the customised files
ADD ubuntu-files/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf
ADD ubuntu-files/Adwaita-Xfce /usr/share/themes/Adwaita-Xfce
ADD ubuntu-files/xfce-perchannel-xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml
ADD ubuntu-files/lang.sh /etc/profile.d/lang.sh
RUN mkdir -p /usr/share/backgrounds
ADD ubuntu-files/background-default.png /usr/share/backgrounds/background-default.png
RUN ln -s /usr/share/icons/Numix-Circle /usr/share/icons/KXicons
RUN ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime

# add the user
RUN useradd --create-home user
RUN echo "user:changeme" | chpasswd && \
    chsh -s /bin/bash user

# add the keyboard maps
COPY keymaps /etc/xrdp/

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT /entrypoint.sh
