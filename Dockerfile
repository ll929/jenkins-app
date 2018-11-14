FROM jenkins/jenkins:lts

USER root

# Install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && \
    apt-get install -y yarn wget

RUN yarn config set registry http://registry.npm.taobao.org/

EXPOSE 8080
EXPOSE 50000
