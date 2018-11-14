FROM jenkins/jenkins:lts

USER root

# Install yarn
RUN apt-get update && \
    apt-get install -y yarn wget

RUN yarn config set registry http://registry.npm.taobao.org/


USER jenkins

EXPOSE 8080
EXPOSE 50000
