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
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz
  && yarn config set registry http://registry.npm.taobao.org/ \
  && yarn config list


# Install react-native
# ------------------------------------------------------

RUN yarn global add react-native-cli

# Install appcenter
# ------------------------------------------------------

RUN yarn global add appcenter-cli

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
