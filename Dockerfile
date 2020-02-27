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

RUN mkdir -p /projects
WORKDIR /projects
SHELL ["/bin/bash", "-c"]


#work with the timezone
#RUN set -euxo pipefail \
#  && apt-get update \
#  && apt install tzdata -y

#ENV TZ=America/Regina
#RUN echo $TZ > /etc/timezone && \
#    rm /etc/localtime && \
#    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
#    dpkg-reconfigure -f noninteractive tzdata && \
#    date


# APT
# packages:
#   curl - installs curl https://github.com/curl/curl
#   git - installs git https://git-scm.com/
#   shellcheck - installs https://github.com/koalaman/shellcheck for optional shell syntax linting
#   build-essential - installs gcc / make / etc
#   g++ - for building c++, necessary for python
#   lsb-core - installs lsb_release for optionally inspecting os version
#   zlib1g-dev - installs zlib https://github.com/madler/zlib, necessary for compilation (some resources are compressed)
#   libssl-dev - installs https://github.com/openssl/openssl, necessary for ssl
#   libffi-dev - installs https://sourceware.org/libffi/, necessary for python / ruby / etc to call c code
#   file - installs https://github.com/file/file, requested by homebrew https://docs.brew.sh/Homebrew-on-Linux#debian-or-ubuntu
RUN set -euxo pipefail \
  && apt-get update \
  && apt-get install -y \
    curl \
    git \
    shellcheck \
    build-essential \
    g++ \
    lsb-core \
    zlib1g-dev \
    libssl-dev \
    libffi-dev \
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

# GOLANG
#   formula: https://formulae.brew.sh/formula/go
# RUN brew install go
# disables go trying to build with extra c extensions
# fixes errors like "gcc-5": executable file not found in $PATH
# ENV CGO_ENABLED=0

# NODE
#   formula: https://formulae.brew.sh/formula/node
RUN set -euxo pipefail \
  && brew install node \
  && npm --version

# RUSTLANG
#   website: https://www.rust-lang.org/
#   install docs: https://www.rust-lang.org/tools/install
# RUN curl https://sh.rustup.rs -ysSf | sh

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

RUN apt install -y zsh sudo net-tools iproute2 vim

RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

# create ssh system
RUN apt install -y openssh-server
EXPOSE 22

RUN mkdir /var/run/sshd \
	&& chmod 0755 /var/run/sshd \
	&& /usr/sbin/sshd

ENV UN="jlovick"

RUN useradd --create-home --shell /bin/zsh --groups sudo $UN  \
    && echo "$UN:$UN" | chpasswd \
    && passwd -e $UN \
    && cp -r ~/.oh-my-zsh /home/$UN/ \
    && cp /home/$UN/.oh-my-zsh/templates/zshrc.zsh-template /home/$UN/.zshrc \
    && chown jlovick.jlovick -R /home/$UN/.oh-my-zsh \
    && chown jlovick.jlovick -R /home/$UN/.zshrc

RUN apt install -y x11-apps ## X11 demo applications (optional)
RUN ifconfig | awk '/inet addr/{print substr($2,6)}' ## Display IP address (optional)

RUN apt install -y libevent-dev ncurses-dev build-essential pkg-config bison flex bash
RUN git clone https://github.com/tmux/tmux.git \
    && cd tmux \
    && sh autogen.sh \
    && ./configure && make \
    && make install

COPY ssh_config /etc/ssh/ssh_config
COPY sshd_config /etc/ssh/sshd_config

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

#ENTRYPOINT ["/usr/bin/bash" "/usr/local/bin/entrypoint.sh"]
ENTRYPOINT  ["/bin/bash", "-c"]

CMD tail -f /dev/null

