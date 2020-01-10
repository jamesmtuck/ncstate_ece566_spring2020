# ECE 466/566 container for easy use on Windows, Linux, MacOS

FROM jamesmtuck/ubuntu-llvm9.0.0-release:latest

LABEL maintainer="jtuck@ncsu.edu"

# RUN apt-get update && apt-get install -y make flex libfl-dev libstdc++-7-dev
RUN apt-get update && apt-get install time

ADD . /ncstate_ece566_spring2020
WORKDIR /ncstate_ece566_spring2020

