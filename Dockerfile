# ubuntu
#   wiki: https://en.wikipedia.org/wiki/Ubuntu
FROM ubuntu:19.10

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# docker docs:
#   run - https://docs.docker.com/engine/reference/builder/#run
#   workdir - https://docs.docker.com/engine/reference/builder/#workdir
#   shell - https://docs.docker.com/engine/reference/builder/#shell
#   entrypoint - https://docs.docker.com/engine/reference/builder/#entrypoint
#   arg - https://docs.docker.com/engine/reference/builder/#arg
#   env - https://docs.docker.com/engine/reference/builder/#env

# Some installers will avoid prompting you if you have the `DEBIAN_FRONTEND` environment variable
# set to `noninteractive`. The vast majority of Dockerfiles will want to have this set, since
# docker build is often done without a human user involved.
#
# Further, we set it as a docker ARG rather than an ENV. Using it as an ARG will make it be set
# only for the duration of this image build (as opposed to being set for all child-builds of this image).
#
# https://github.com/moby/moby/issues/4032
ARG DEBIAN_FRONTEND=noninteractive

# tool docs:
#   bash - https://www.gnu.org/software/bash/manual/html_node/index.html
#   mkdir - http://manpages.ubuntu.com/manpages/bionic/man1/mkdir.1.html (swap ubuntu version as needed)
#
# bash (as oppossed to the default, sh) is required for `set -euxo pipefile` calls.
# "what is `set -euxo pipefile` for?"
#   docs: https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
#   blog post: https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

RUN mkdir -p /source_packages
WORKDIR /source_packages
SHELL ["/bin/bash", "-c"]
RUN apt update

# more general utilities....
# zsh, sshd etc
RUN apt install -y zsh sudo net-tools iproute2 vim tzdata

#===================
# Timezone settings
#===================
ENV TZ=America/Regina
RUN echo $TZ > /etc/timezone && \
    touch /etc/localtime && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    date

#========================================
# Add normal user with passwordless sudo
#========================================
ARG UN
ENV NORMAL_USER $UN
ENV NORMAL_GROUP $NORMAL_USER
ENV NORMAL_USER_UID 998
ENV NORMAL_USER_GID 997
RUN groupadd -g ${NORMAL_USER_GID} ${NORMAL_GROUP}

RUN useradd ${NORMAL_USER} --uid ${NORMAL_USER_UID} \
         --shell /bin/zsh  --gid ${NORMAL_USER_GID} \
         --create-home

RUN echo "$UN:$UN" | chpasswd \
  && passwd -e $UN \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers

ENV NORMAL_USER_HOME /home/${NORMAL_USER}

# APT
# packages:
RUN set -euxo pipefail \
  && apt-get update \
  && apt-get install -y \
  	wget \
    curl \
    git \
    shellcheck \
    build-essential \
    g++ \
    lsb-core \
    zlib1g-dev \
    libssl-dev \
    libffi-dev \
    autoconf \
    automake \
    bzip2 \
    file \
    g++ \
    gcc \
    imagemagick \
    libbz2-dev \
    libc6-dev \
    libcurl4-openssl-dev \
    libdb-dev \
    libevent-dev \
    libffi-dev \
    libgeoip-dev \
    libglib2.0-dev \
    libjpeg-dev \
    liblzma-dev \
    libmagickcore-dev \
    libmagickwand-dev \
    libmysqlclient-dev \
    libncurses-dev \
    libpng-dev \
    libpq-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libtool \
    libwebp-dev \
    libxml2-dev \
    libxslt-dev \
    libyaml-dev \
    make \
    patch \
    xz-utils \
    zlib1g-dev \
    file

# HOMEBREW
#   website: https://docs.brew.sh/Homebrew-on-Linux
#   example: https://github.com/Linuxbrew/docker/blob/master/bionic/Dockerfile
#
# The code you see here is a mix of my personal preferences, and the example dockerfile
# linked above.
#
# locale-gen / LC_ALL details: https://github.com/lynncyrin/base-image/issues/44
# sbin notes: https://github.com/lynncyrin/base-image/issues/46

ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH
RUN set -euxo pipefail \
  && git clone https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew/Homebrew \
  && mkdir /home/linuxbrew/.linuxbrew/bin \
  && ln -s ../Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/ \
  && brew config \
  && echo "brew install done!"

RUN echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile

# PYTHON
#   website: https://www.python.org/
#   source: https://github.com/python/cpython
#   inspiration: https://github.com/docker-library/python
#
# The `git clone ...` is a personal preference, pulled from some work I've
# done with custom homebrew taps. The big upside is that it helps enable the
# eventual future where I start contributing to python itself.
#
# This section `./configure ... make install` is from the python documentation
# here: https://github.com/python/cpython#build-instructions. As an opinionated
# change, we `make install` without sudo.
#
# The `ln -s` lines are a personal preference, I like using symlinks to add
# things into my path (with shortened names). This issue
# https://github.com/lynncyrin/base-image/issues/26 describes the long-term
# future here.
#
# We use `python -c` to get python to test itself. At some point in the future
# that'll change to use py-sh instead. The issue for that is here
# https://github.com/lynncyrin/base-image/issues/35.
#
# The last step is pip installing various python tools that I think are ✨ nice ✨.
# And then testing their versions (relevant issue https://github.com/lynncyrin/base-image/issues/29)

ENV PYTHON_VERSION="3.8.2"
RUN set -euxo pipefail \
  && git clone \
    --depth "1" \
    --branch "v$PYTHON_VERSION" \
    --config "advice.detachedHead=false" \
    "https://github.com/python/cpython.git" \
  && cd cpython \
  && ./configure \
  && make \
  && make install \
  && ln -s /usr/local/bin/python3 /usr/local/bin/python \
  && python -c "import os, platform; assert platform.python_version() == os.getenv('PYTHON_VERSION')" \
  && ln -s /usr/local/bin/pip3 /usr/local/bin/pip \
  && pip install --upgrade pip \
  && pip install ptipython pipenv \
  && pipenv --version \
  && echo "python install done!"

#===========
# Ruby time
#===========
ENV RUBY_MAJOR 2.7
ENV RUBY_VERSION 2.7.0
ENV RUBY_DOWNLOAD_SHA256 8c99aa93b5e2f1bc8437d1bbbefd27b13e7694025331f77245d0c068ef1f8cbe

# skip installing gem documentation
RUN echo 'install: --no-document\nupdate: --no-document' >> "$HOME/.gemrc"

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN apt-get update -qqy \
  && apt-get install -y bison libgdbm-dev ruby \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /usr/src/ruby \
  && curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
  && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
  && tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
  && rm ruby.tar.gz \
  && cd /usr/src/ruby \
  && autoconf \
  && ./configure --disable-install-doc \
  && make -j"$(nproc)" \
  && make install \
  && apt-get purge -y --auto-remove ruby \
  && gem update --system \
  && rm -r /usr/src/ruby \
  && rm -rf /var/lib/apt/lists/*

# install things globally, for great justice
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH


RUN gem install bundler \
  && bundle config --global path "$GEM_HOME" \
  && bundle config --global bin "$GEM_HOME/bin" \
  && bundle config --global silence_root_warning true

# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME

# GOLANG
#   formula: https://formulae.brew.sh/formula/go
RUN brew install go
# disables go trying to build with extra c extensions
# fixes errors like "gcc-5": executable file not found in $PATH
ENV CGO_ENABLED=0

# NODE
#   formula: https://formulae.brew.sh/formula/node
RUN set -euxo pipefail \
  && brew install node \
  && npm --version

# RUSTLANG
#   website: https://www.rust-lang.org/
#   install docs: https://www.rust-lang.org/tools/install
RUN curl https://sh.rustup.rs > /root/get_rust.sh
RUN chmod a+x /root/get_rust.sh
RUN /root/get_rust.sh -y
RUN echo "source ~/.cargo/env" >> ~/.profile

RUN apt update
RUN apt install -y software-properties-common
RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)" \\
	&& apt update


# Crystal
# see  https://github.com/crystal-lang/crystal/wiki/All-required-libraries
RUN apt-get install \
  libbsd-dev \
  libedit-dev \
  libevent-dev \
  libgmp-dev \
  libgmpxx4ldbl \
  libssl-dev \
  libxml2-dev \
  libyaml-dev \
  automake \
  libtool \
  git \
  llvm-8 \
  llvm-8-dev \
  lld-8 \
  libpcre3-dev \
  build-essential -y

RUN ln -sf /usr/bin/ld.lld-8 /usr/bin/ld.lld

RUN git clone https://github.com/ivmai/bdwgc.git \
	&& cd bdwgc \
	&& git clone https://github.com/ivmai/libatomic_ops.git \
	&& autoreconf -vif \
	&& ./configure --enable-static --disable-shared \
	&& make -j \
	&& make check \
	&& make install

RUN curl -sL "https://keybase.io/crystal/pgp_keys.asc" | apt-key add -
RUN echo "deb https://dist.crystal-lang.org/apt crystal main" | tee /etc/apt/sources.list.d/crystal.list
RUN apt-get update
RUN apt install -y crystal

# nim
RUN curl https://nim-lang.org/choosenim/init.sh > /root/get_nim.sh
RUN chmod a+x /root/get_nim.sh
RUN /root/get_nim.sh -y
RUN echo "export PATH=~/.nimble/bin:$PATH" >> /root/.profile

# Elixir
RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb \
    && sudo dpkg -i erlang-solutions_2.0_all.deb \
    && apt update \
    && apt install -y esl-erlang \
           elixir

#  End of computer langs
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN cp /root/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
RUN mkdir -p /root/.oh-my-zsh/custom/themes
COPY jlovick.zsh-theme /root/.oh-my-zsh/custom/themes/
COPY dir_colors /root/.dir_colors

# create ssh system
RUN apt install -y openssh-server
EXPOSE 22

RUN mkdir /var/run/sshd \
	&& chmod 0755 /var/run/sshd \
	&& /usr/sbin/sshd



RUN apt install -y x11-apps ## X11 demo applications (optional)
RUN ifconfig | awk '/inet addr/{print substr($2,6)}' ## Display IP address (optional)

RUN apt install -y libevent-dev ncurses-dev build-essential pkg-config bison flex bash
RUN git clone https://github.com/tmux/tmux.git \
    && cd tmux \
    && sh autogen.sh \
    && ./configure && make \
    && make install
COPY tmux.conf /root/.tmux.conf
RUN git clone https://github.com/tmux-plugins/tpm /root/.tmux/plugins/tpm

COPY ssh_config /etc/ssh/ssh_config
COPY sshd_config /etc/ssh/sshd_config

# final clean up
ARG UN
RUN cp ~/.profile /home/$UN/.profile
COPY zshrc /root/.zshrc
COPY zshrc /home/$UN/.zshrc
COPY dir_colors /home/$UN/.dir_colors
COPY dir_colors /root/.dir_colors
RUN cp -r /root/.oh-my-zsh /home/$UN/.oh-my-zsh
RUN cp /root/.tmux.conf /home/$UN/.tmux.conf
RUN cp -r /root/.tmux /home/$UN/.tmux

RUN cp -r /root/.rustup /home/$UN/.rustup
RUN cp -r /root/.cargo /home/$UN/.cargo
RUN cp -r /root/.nimble /home/$UN/.nimble
RUN cp -r /root/.choosenim /home/$UN/.choosenim
RUN cat /root/.choosenim/current | sed "s#root#home/$UN#" > /home/jlovick/.choosenim/current

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /projects
WORKDIR /projects

SHELL ["/bin/bash", "-c"]

ENTRYPOINT  ["/bin/bash", "-c"]
RUN chown -R $UN.$UN /home/$UN

CMD tail -f /dev/null

