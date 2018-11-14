FROM jenkins/jenkins:lts

USER root

# Install yarn
RUN apt-get update && \
    apt-get install -y yarn wget

# Install Node
ADD nodesource/setup_8.x /tmp/
RUN bash /tmp/setup_8.x
RUN apt-get update && \
    apt-get autoremove && \
    apt-get install -y build-essential \
                       libfontconfig \
                       git \
                       nodejs

USER jenkins

EXPOSE 8080
EXPOSE 50000
