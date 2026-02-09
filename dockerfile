FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    git \
    build-essential \
    autoconf \
    curl \
    libncurses5-dev \
    libncursesw5-dev \
    libncurses-dev \
    libtinfo-dev \
    bison \
    file \
    flex \
    xorg-dev
    # ここまででビルド自体は成功
    # 


RUN git clone https://github.com/openxm-org/OpenXM
RUN git clone https://github.com/openxm-org/OpenXM_contrib2


WORKDIR /OpenXM/src
RUN make configure
RUN make install

WORKDIR /OpenXM/rc
RUN make && mkdir ~/bin && cp openxm ~/bin


CMD ["/bin/bash"]
