FROM python:3.7.1-stretch

ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y vim tmux

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly-2018-10-24

ENV PATH /root/.cargo/bin:$PATH

RUN apt-get update && apt-get install -y bison flex libgmp-dev libmpc-dev libmpfr-dev libntl-dev libflint-dev

WORKDIR /usr/src/HoneyBadgerMPC

RUN pip install --upgrade pip

COPY . /usr/src/HoneyBadgerMPC

RUN pip install pairing/

RUN wget https://crypto.stanford.edu/pbc/files/pbc-0.5.14.tar.gz
RUN tar -xvf pbc-0.5.14.tar.gz
RUN cd pbc-0.5.14 && ./configure && make && make install

ENV LIBRARY_PATH /usr/local/lib
ENV LD_LIBRARY_PATH /usr/local/lib

# Make sh point to bash
# This is being changed since it will avoid any errors in the `launch_mpc.sh` script
# which relies on certain code that doesn't work in container's default shell.
RUN ln -sf bash /bin/sh

RUN git clone https://github.com/JHUISI/charm.git
RUN cd charm && ./configure.sh && make install

# This is needed otherwise the build for the power sum solver will fail.
# This is a known issue in the version of libflint-dev in apt.
# https://github.com/wbhart/flint2/issues/217
# This has been fixed if we pull the latest code from the repo. However, we want
# to avoid compiling the lib from the source since it adds 20 minutes to the build.
RUN sed -i '30c #include "flint/flint.h"' /usr/include/flint/flintxx/flint_classes.h

ARG BUILD
RUN pip install Cython
RUN pip install --no-cache-dir -e .[$BUILD]

RUN make -C apps/shuffle/cpp

RUN echo "alias cls=\"clear && printf '\e[3J'\"" >> ~/.bashrc
