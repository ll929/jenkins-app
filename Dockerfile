FROM jenkins/jenkins:lts

RUN RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
        apt-get update && apt-get install -y yarn

RUN yarn config set registry http://registry.npm.taobao.org/

EXPOSE 8080
EXPOSE 50000
