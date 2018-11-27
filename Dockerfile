FROM jenkins/jenkins:lts

USER root

RUN groupadd --gid 1113 node \
  && useradd --uid 1113 --gid node --shell /bin/bash --create-home node

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done

ENV NODE_VERSION 8.12.0

RUN buildDeps='xz-utils' \
    && ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x64';; \
      ppc64el) ARCH='ppc64le';; \
      s390x) ARCH='s390x';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armv7l';; \
      i386) ARCH='x86';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && set -x \
    && apt-get update && apt-get install -y ca-certificates curl wget $buildDeps --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && apt-get purge -y --auto-remove $buildDeps \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV YARN_VERSION 1.12.3

RUN set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && yarn config set registry http://registry.npm.taobao.org/ \
  && yarn config list


# Install react-native
# ------------------------------------------------------

RUN yarn global add react-native-cli

# Install appcenter
# ------------------------------------------------------

RUN yarn global add appcenter-cli

# Install gcc depend
# ------------------------------------------------------
RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		bzip2 \
		dpkg-dev \
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
		libgdbm-dev \
		libgeoip-dev \
		libglib2.0-dev \
		libjpeg-dev \
		libkrb5-dev \
		liblzma-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libncurses5-dev \
		libncursesw5-dev \
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
		\
# https://lists.debian.org/debian-devel-announce/2016/09/msg00000.html
		$( \
# if we use just "apt-cache show" here, it returns zero because "Can't select versions from package 'libmysqlclient-dev' as it is purely virtual", hence the pipe to grep
			if apt-cache show 'default-libmysqlclient-dev' 2>/dev/null | grep -q '^Version:'; then \
				echo 'default-libmysqlclient-dev'; \
			else \
				echo 'libmysqlclient-dev'; \
			fi \
		) \
	; \
	rm -rf /var/lib/apt/lists/*

# Install gcc
# ------------------------------------------------------

RUN set -ex; \
	if ! command -v gpg > /dev/null; then \
		apt-get update; \
		apt-get install -y --no-install-recommends \
			gnupg \
			dirmngr \
		; \
		rm -rf /var/lib/apt/lists/*; \
	fi

# https://gcc.gnu.org/mirrors.html
ENV GPG_KEYS \
# 1024D/745C015A 1999-11-09 Gerald Pfeifer <gerald@pfeifer.com>
	B215C1633BCA0477615F1B35A5B3A004745C015A \
# 1024D/B75C61B8 2003-04-10 Mark Mitchell <mark@codesourcery.com>
	B3C42148A44E6983B3E4CC0793FA9B1AB75C61B8 \
# 1024D/902C9419 2004-12-06 Gabriel Dos Reis <gdr@acm.org>
	90AA470469D3965A87A5DCB494D03953902C9419 \
# 1024D/F71EDF1C 2000-02-13 Joseph Samuel Myers <jsm@polyomino.org.uk>
	80F98B2E0DAB6C8281BDF541A7C8C3B2F71EDF1C \
# 2048R/FC26A641 2005-09-13 Richard Guenther <richard.guenther@gmail.com>
	7F74F97C103468EE5D750B583AB00996FC26A641 \
# 1024D/C3C45C06 2004-04-21 Jakub Jelinek <jakub@redhat.com>
	33C235A34C46AA3FFB293709A328C3A2C3C45C06
RUN set -ex; \
	for key in $GPG_KEYS; do \
		gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done

# https://gcc.gnu.org/mirrors.html
ENV GCC_MIRRORS \
		https://ftpmirror.gnu.org/gcc \
		https://bigsearcher.com/mirrors/gcc/releases \
		https://mirrors-usa.go-parts.com/gcc/releases \
		https://mirrors.concertpass.com/gcc/releases \
		http://www.netgull.com/gcc/releases

# Last Modified: 2018-07-26
ENV GCC_VERSION 8.2.0
# Docker EOL: 2020-01-26

RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		dpkg-dev \
		flex \
	; \
	rm -r /var/lib/apt/lists/*; \
	\
	_fetch() { \
		local fetch="$1"; shift; \
		local file="$1"; shift; \
		for mirror in $GCC_MIRRORS; do \
			if curl -fL "$mirror/$fetch" -o "$file"; then \
				return 0; \
			fi; \
		done; \
		echo >&2 "error: failed to download '$fetch' from several mirrors"; \
		return 1; \
	}; \
	\
	_fetch "gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz.sig" 'gcc.tar.xz.sig' \
# 6.5.0 (https://mirrors.kernel.org/gnu/gcc/6.5.0/), no gcc- prefix
		|| _fetch "$GCC_VERSION/gcc-$GCC_VERSION.tar.xz.sig"; \
	_fetch "gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz" 'gcc.tar.xz' \
		|| _fetch "$GCC_VERSION/gcc-$GCC_VERSION.tar.xz" 'gcc.tar.xz'; \
	gpg --batch --verify gcc.tar.xz.sig gcc.tar.xz; \
	mkdir -p /usr/src/gcc; \
	tar -xf gcc.tar.xz -C /usr/src/gcc --strip-components=1; \
	rm gcc.tar.xz*; \
	\
	cd /usr/src/gcc; \
	\
# "download_prerequisites" pulls down a bunch of tarballs and extracts them,
# but then leaves the tarballs themselves lying around
	./contrib/download_prerequisites; \
	{ rm *.tar.* || true; }; \
	\
# explicitly update autoconf config.guess and config.sub so they support more arches/libcs
	for f in config.guess config.sub; do \
		wget -O "$f" "https://git.savannah.gnu.org/cgit/config.git/plain/$f?id=7d3d27baf8107b630586c962c057e22149653deb"; \
# find any more (shallow) copies of the file we grabbed and update them too
		find -mindepth 2 -name "$f" -exec cp -v "$f" '{}' ';'; \
	done; \
	\
	dir="$(mktemp -d)"; \
	cd "$dir"; \
	\
	extraConfigureArgs=''; \
	dpkgArch="$(dpkg --print-architecture)"; \
	case "$dpkgArch" in \
# with-arch: https://anonscm.debian.org/viewvc/gcccvs/branches/sid/gcc-6/debian/rules2?revision=9450&view=markup#l491
# with-float: https://anonscm.debian.org/viewvc/gcccvs/branches/sid/gcc-6/debian/rules.defs?revision=9487&view=markup#l416
# with-mode: https://anonscm.debian.org/viewvc/gcccvs/branches/sid/gcc-6/debian/rules.defs?revision=9487&view=markup#l376
		armel) \
			extraConfigureArgs="$extraConfigureArgs --with-arch=armv4t --with-float=soft" \
			;; \
		armhf) \
			extraConfigureArgs="$extraConfigureArgs --with-arch=armv7-a --with-float=hard --with-fpu=vfpv3-d16 --with-mode=thumb" \
			;; \
		\
# with-arch-32: https://anonscm.debian.org/viewvc/gcccvs/branches/sid/gcc-6/debian/rules2?revision=9450&view=markup#l590
		i386) \
			osVersionID="$(set -e; . /etc/os-release; echo "$VERSION_ID")"; \
			case "$osVersionID" in \
				8) extraConfigureArgs="$extraConfigureArgs --with-arch-32=i586" ;; \
				*) extraConfigureArgs="$extraConfigureArgs --with-arch-32=i686" ;; \
			esac; \
# TODO for some reason, libgo + i386 fails on https://github.com/gcc-mirror/gcc/blob/gcc-7_1_0-release/libgo/runtime/proc.c#L154
# "error unknown case for SETCONTEXT_CLOBBERS_TLS"
			;; \
	esac; \
	\
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	/usr/src/gcc/configure \
		--build="$gnuArch" \
		--disable-multilib \
		--enable-languages=c,c++,fortran,go \
		$extraConfigureArgs \
	; \
	make -j "$(nproc)"; \
	make install-strip; \
	\
	cd ..; \
	\
	rm -rf "$dir"; \
	\
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

# gcc installs .so files in /usr/local/lib64...
RUN set -ex; \
	echo '/usr/local/lib64' > /etc/ld.so.conf.d/local-lib64.conf; \
	ldconfig -v

# ensure that alternatives are pointing to the new compiler and that old one is no longer used
RUN set -ex; \
	dpkg-divert --divert /usr/bin/gcc.orig --rename /usr/bin/gcc; \
	dpkg-divert --divert /usr/bin/g++.orig --rename /usr/bin/g++; \
	dpkg-divert --divert /usr/bin/gfortran.orig --rename /usr/bin/gfortran; \
	update-alternatives --install /usr/bin/cc cc /usr/local/bin/gcc 999

# Install watchman
# ------------------------------------------------------

ENV WATCH_MAN_VERSION 4.9.0

RUN apt-get update \
 && apt-get -y install libssl-dev \
 && apt-get -y install python-dev \
 && apt-get -y install autoconf \
 && apt-get -y install automake \
 && apt-get -y install libtool \
 && apt-get -y install pkg-config

RUN gcc -v

RUN cd /opt \
 && wget -q https://codeload.github.com/facebook/watchman/zip/v${WATCH_MAN_VERSION} -O watchman.zip \
 && unzip -q watchman.zip -d /opt/watchman \
 && cd /opt/watchman/watchman-${WATCH_MAN_VERSION} \
 && ./autogen.sh \
 && ./configure \
 && make \
 && make install \
 && cd /opt \
 && rm watchman.zip \
 && rm -rf watchman

RUN watchman --version

# ------------------------------------------------------

ENV ANDROID_HOME /opt/android-sdk-linux

# ------------------------------------------------------
# --- Install required tools

RUN apt-get update -qq

# Base (non android specific) tools
# -> should be added to bitriseio/docker-bitrise-base

# Dependencies to execute Android builds
RUN dpkg --add-architecture i386
RUN apt-get update -qq
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-8-jdk libc6:i386 libstdc++6:i386 libgcc1:i386 libncurses5:i386 libz1:i386

# ------------------------------------------------------
# --- Download Android SDK tools into $ANDROID_HOME

RUN cd /opt \
    && wget -q https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip -O android-sdk-tools.zip \
    && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME} \
    && rm android-sdk-tools.zip

ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools

# ------------------------------------------------------
# --- Install Android SDKs and other build packages

# Other tools and resources of Android SDK
#  you should only install the packages you need!
# To get a full list of available options you can use:
#  sdkmanager --list

# Accept licenses before installing components, no need to echo y for each component
# License is valid for all the standard components in versions installed from this file
# Non-standard components: MIPS system images, preview versions, GDK (Google Glass) and Android Google TV require separate licenses, not accepted there
RUN yes | sdkmanager --licenses

# Platform tools
RUN sdkmanager "emulator" "tools" "platform-tools"

# SDKs
# Please keep these in descending order!
# The `yes` is for accepting all non-standard tool licenses.

# Please keep all sections in descending order!
RUN yes | sdkmanager \
    "platforms;android-28"
#RUN yes | sdkmanager \
#    "platforms;android-27"
#RUN yes | sdkmanager \
#    "platforms;android-26"
#RUN yes | sdkmanager \
#    "platforms;android-25"
#RUN yes | sdkmanager \
#    "platforms;android-24"
#RUN yes | sdkmanager \
#    "platforms;android-23"
#RUN yes | sdkmanager \
#    "platforms;android-22"
#RUN yes | sdkmanager \
#    "platforms;android-21"
#RUN yes | sdkmanager \
#    "platforms;android-19"
#RUN yes | sdkmanager \
#    "platforms;android-17"
#RUN yes | sdkmanager \
#    "platforms;android-15"
RUN yes | sdkmanager \
    "build-tools;28.0.3"
#RUN yes | sdkmanager \
#    "build-tools;28.0.2"
#RUN yes | sdkmanager \
#    "build-tools;28.0.1"
#RUN yes | sdkmanager \
#    "build-tools;28.0.0"
#RUN yes | sdkmanager \
#    "build-tools;27.0.3"
#RUN yes | sdkmanager \
#    "build-tools;27.0.2"
#RUN yes | sdkmanager \
#    "build-tools;27.0.1"
#RUN yes | sdkmanager \
#    "build-tools;27.0.0"
#RUN yes | sdkmanager \
#    "build-tools;26.0.2"
#RUN yes | sdkmanager \
#    "build-tools;26.0.1"
#RUN yes | sdkmanager \
#    "build-tools;25.0.3"
#RUN yes | sdkmanager \
#    "build-tools;24.0.3"
#RUN yes | sdkmanager \
#    "build-tools;23.0.3"
#RUN yes | sdkmanager \
#    "build-tools;22.0.1"
#RUN yes | sdkmanager \
#    "build-tools;21.1.2"
#RUN yes | sdkmanager \
#    "build-tools;19.1.0"
#RUN yes | sdkmanager \
#    "build-tools;17.0.0"
#RUN yes | sdkmanager \
#    "system-images;android-28;google_apis;x86"
#RUN yes | sdkmanager \
#    "system-images;android-26;google_apis;x86"
#RUN yes | sdkmanager \
#    "system-images;android-25;google_apis;armeabi-v7a"
#RUN yes | sdkmanager \
#    "system-images;android-24;default;armeabi-v7a"
#RUN yes | sdkmanager \
#    "system-images;android-22;default;armeabi-v7a"
#RUN yes | sdkmanager \
#    "system-images;android-19;default;armeabi-v7a"
RUN yes | sdkmanager \
    "extras;android;m2repository"
RUN yes | sdkmanager \
    "extras;google;m2repository"
RUN yes | sdkmanager \
    "extras;google;google_play_services"
RUN yes | sdkmanager \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2"
RUN yes | sdkmanager \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.1"
RUN yes | sdkmanager \
    "add-ons;addon-google_apis-google-23"
RUN yes | sdkmanager \
    "add-ons;addon-google_apis-google-22"
RUN yes | sdkmanager \
    "add-ons;addon-google_apis-google-21"



# ------------------------------------------------------
# --- Install Gradle from PPA

# Gradle PPA
RUN apt-get update \
 && apt-get -y install gradle \
 && gradle -v


# ------------------------------------------------------
# --- Install Maven 3 from PPA

RUN apt-get purge maven maven2 \
 && apt-get update \
 && apt-get -y install maven \
 && mvn --version


# ------------------------------------------------------
# --- Install Ruby

RUN apt-get update \
 && apt-get -y install ruby-dev \
 && apt-get -y install rubygems \
 && apt-get -y install build-essential patch \
 && apt-get -y install libgmp-dev


# ------------------------------------------------------
# --- Install Fastlane

RUN gem install fastlane -NV \
 && fastlane --version


# ------------------------------------------------------
# --- Cleanup and rev num

# Cleaning
RUN apt-get clean

ENV BITRISE_DOCKER_REV_NUMBER_ANDROID v2018_11_14_1


#USER jenkins

EXPOSE 8080
EXPOSE 50000
