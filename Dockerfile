FROM opensuse:tumbleweed
MAINTAINER Fabian Neuschmidt fabian@neuschmidt.de

ARG branch=master

# Set the locale
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en PATH=$PATH:/root/pmd-bin-5.4.1/bin:/root/dart-sdk/bin:/coala-bears/node_modules/.bin:/root/bakalint-0.4.0

# Create symlink for cache
RUN mkdir -p /root/.local/share/coala && \
  ln -s /root/.local/share/coala /cache

# Add packaged flawfinder
RUN zypper addrepo http://download.opensuse.org/repositories/home:illuusio/openSUSE_Tumbleweed/home:illuusio.repo && \
  # Add repo for luarocks
  zypper addrepo -f \
    http://download.opensuse.org/repositories/devel:/languages:/lua/openSUSE_Factory/ \
    devel:languages:lua && \
  # Use Leap for nodejs
  zypper addrepo http://download.opensuse.org/repositories/devel:languages:nodejs/openSUSE_Leap_42.2/devel:languages:nodejs.repo && \
  # Add repo for rubygem-bundler
  zypper addrepo http://download.opensuse.org/repositories/home:AtastaChloeD:ChiliProject/openSUSE_Factory/home:AtastaChloeD:ChiliProject.repo && \
  # Package dependencies
  time zypper --no-gpg-checks --non-interactive install \
    bzr \
    cppcheck \
    curl \
    expect \
    flawfinder \
    gcc-c++ \
    gcc-fortran \
    git \
    go \
    gsl \
    mercurial \
    hlint \
    indent \
    java-1_8_0-openjdk-headless \
    julia \
    libcholmod-3_0_6 \
    libclang3_8 \
    libcurl-devel \
    # icu needed by R stringi
    libicu-devel \
    libncurses5 \
    libopenssl-devel \
    libpcre2-8-0 \
    # libxml2-tools provides xmllint
    libxml2-tools \
    # linux-glibc-devel needed for Ruby native extensions
    linux-glibc-devel \
    lua \
    lua-devel \
    luarocks \
    m4 \
    nodejs \
    npm \
    patch \
    perl-Perl-Critic \
    php \
    php7-pear \
    # Needed for PHP CodeSniffer
    php7-pear-Archive_Tar \
    php7-tokenizer \
    php7-xmlwriter \
    python3 \
    python3-dbm \
    python3-gobject \
    python3-pip \
    python3-setuptools \
    R-base \
    ruby \
    ruby-devel \
    ruby2.2-rubygem-bundler \
    ShellCheck \
    subversion \
    sudo \
    tar \
    texlive-chktex \
    unzip && \
  time rpm -e -f --nodeps -v \
    aaa_base \
    cron \
    cronie \
    dbus-1 \
    fdupes \
    fontconfig \
    fonts-config \
    gio-branding-openSUSE \
    glib2-tools \
    kbd \
    iproute2 \
    kmod \
    libasan3 \
    libdrm_amdgpu1 \
    libdrm_intel1 \
    libdrm_nouveau2 \
    libdrm_radeon1 \
    libnl-config \
    libthai-data \
    libwayland-server0 \
    libxslt-tools \
    libXss1 \
    lksctp-tools \
    logrotate \
    ncurses-utils \
    openssh \
    openslp \
    perl-File-ShareDir \
    perl-Net-DBus \
    perl-Pod-Coverage \
    perl-Test-Pod \
    perl-Test-Pod-Coverage \
    perl-X11-Protocol \
    postfix \
    php7-zlib \
    python-cssselect \
    python-curses \
    python-javapackages \
    python-lxml \
    python-Pygments \
    python-pyxb \
    python-setuptools \
    python-six \
    python-xml \
    R-core-doc \
    rsync \
    rsyslog \
    sysconfig \
    sysconfig-netconfig \
    syslog-service \
    systemd \
    systemd-presets-branding-openSUSE \
    texlive-gsftopk \
    texlive-gsftopk-bin \
    texlive-kpathsea \
    texlive-kpathsea-bin \
    texlive-tetex-bin \
    texlive-texconfig \
    texlive-texconfig-bin \
    texlive-texlive.infra \
    texlive-updmap-map \
    util-linux-systemd \
    wicked \
    wicked-service \
    xhost \
    xorg-x11-fonts \
    xorg-x11-fonts-core \
    && \
  rm -rf \
    /usr/lib64/ruby/gems/2.2.0/gems/bundler-*/man/* \
    /usr/lib64/R/library/*/po/* \
    /usr/lib64/R/library/*/doc/* \
    /usr/lib64/R/library/*/help/* \
    /usr/lib64/R/library/*/demo/* \
    /usr/lib64/R/library/*/man/* \
    /usr/lib64/R/library/*/NEWS \
    && \
  # Clear zypper cache
  time zypper clean -a

# Coala setup and python deps
RUN cd / && \
  git clone --depth 1 --branch=$branch https://github.com/coala/coala.git && \
  git clone --depth 1 --branch=$branch https://github.com/coala/coala-bears.git && \
  git clone --depth 1 https://github.com/coala/coala-quickstart.git && \
  time pip3 install --no-cache-dir \
    -e /coala \
    -e '/coala-bears[alldeps]' \
    -e /coala-quickstart \
    -r /coala/test-requirements.txt && \
  cd coala-bears && \
  # NLTK data
  time python3 -m nltk.downloader punkt maxent_treebank_pos_tagger averaged_perceptron_tagger && \
  # Remove Ruby directive from Gemfile as this image has 2.2.5
  sed -i '/^ruby/d' Gemfile && \
  # Ruby dependencies
  time bundle install --system && rm -rf ~/.bundle && \
  # NPM dependencies
  time npm install && npm cache clean

RUN time pear install PHP_CodeSniffer

# Dart Lint setup
RUN curl -fsSL https://storage.googleapis.com/dart-archive/channels/stable/release/1.14.2/sdk/dartsdk-linux-x64-release.zip -o /root/dart-sdk.zip && \
  unzip -n /root/dart-sdk.zip -d ~/ && \
  rm -rf /root/dart-sdk.zip

# GO setup
RUN source /etc/profile.d/go.sh && time go get -u \
  github.com/golang/lint/golint \
  golang.org/x/tools/cmd/goimports \
  sourcegraph.com/sqs/goreturns \
  golang.org/x/tools/cmd/gotype \
  github.com/kisielk/errcheck

# # Infer setup using opam
# RUN useradd -ms /bin/bash opam && usermod -G wheel opam
# RUN echo "opam ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers
# # necessary because there is a sudo bug in the base image
# RUN sed -i '51 s/^/#/' /etc/security/limits.conf
# USER opam
# WORKDIR /home/opam
# ADD https://raw.github.com/ocaml/opam/master/shell/opam_installer.sh opam_installer.sh
# RUN sudo sh opam_installer.sh /usr/local/bin
# RUN yes | /usr/local/bin/opam init --comp 4.02.1
# RUN opam switch 4.02.3 && \
#   eval `opam config env` && \
#   opam update && \
#   opam pin add -y merlin 'https://github.com/the-lambda-church/merlin.git#reason-0.0.1' && \
#   opam pin add -y merlin_extend 'https://github.com/let-def/merlin-extend.git#reason-0.0.1' && \
#   opam pin add -y reason 'https://github.com/facebook/reason.git#0.0.6'
# ADD https://github.com/facebook/infer/releases/download/v0.9.0/infer-linux64-v0.9.0.tar.xz infer-linux64-v0.9.0.tar.xz
# RUN sudo tar xf infer-linux64-v0.9.0.tar.xz
# WORKDIR /home/opam/infer-linux64-v0.9.0
# RUN opam pin add -y --no-action infer . && \
#   opam install --deps-only --yes infer && \
#   ./build-infer.sh java
# USER root
# WORKDIR /
# ENV PATH=$PATH:/home/opam/infer-linux64-v0.9.0/infer/bin

# Julia setup
RUN time julia -e 'Pkg.add("Lint")' && \
  rm -rf \
    ~/.julia/.cache \
    ~/.julia/v0.5/.cache \
    ~/.julia/v0.5/METADATA \
    ~/.julia/v0.5/*/.git \
    ~/.julia/v0.5/*/test \
    ~/.julia/v0.5/*/docs

# Lua commands
RUN time luarocks install luacheck

# PMD setup
RUN curl -fsSL https://github.com/pmd/pmd/releases/download/pmd_releases/5.4.1/pmd-bin-5.4.1.zip -o /root/pmd.zip && \
  unzip /root/pmd.zip -d /root/ && \
  rm -rf /root/pmd.zip

# R setup
RUN mkdir -p ~/.RLibrary && \
  echo '.libPaths( c( "~/.RLibrary", .libPaths()) )' >> ~/.Rprofile && \
  echo 'options(repos=structure(c(CRAN="http://cran.rstudio.com")))' >> ~/.Rprofile && \
  export ICUDT_DIR=/usr/share/icu/57.1/ && \
  time R -e "install.packages(c('lintr', 'formatR'), dependencies=TRUE, verbose=FALSE)" && \
  rm -rf \
    ~/.RLibrary/*/annouce/* \
    ~/.RLibrary/*/po/* \
    ~/.RLibrary/*/demo/* \
    ~/.RLibrary/*/doc/* \
    ~/.RLibrary/*/examples/* \
    ~/.RLibrary/*/help/* \
    ~/.RLibrary/*/html/* \
    ~/.RLibrary/*/man/* \
    ~/.RLibrary/*/tests/ \
    ~/.RLibrary/*/NEWS \
    ~/.RLibrary/Rcpp/unitTests/ \
    && \
  unset ICUDT_DIR && export ICUDT_DIR

# Tailor (Swift) setup
RUN curl -fsSL https://tailor.sh/install.sh | sed 's/read -r CONTINUE < \/dev\/tty/CONTINUE=y/' > install.sh && \
  time /bin/bash install.sh

# # VHDL Bakalint Installation
RUN curl -L 'http://downloads.sourceforge.net/project/fpgalibre/bakalint/0.4.0/bakalint-0.4.0.tar.gz' > /root/bl.tar.gz && \
  tar xf /root/bl.tar.gz -C /root/ && \
  rm -rf /root/bl.tar.gz

# Entrypoint script
ADD docker-coala.sh /usr/local/bin/
CMD ["/usr/local/bin/docker-coala.sh"]
