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
    xorg-dev \
    # ここまででビルド自体は成功
    texinfo \
    sharutils \
    latex2html \
    ghostscript \
    netpbm \
    texlive-lang-japanese \
    default-jdk \
    libcerf \
    pkg-config \
    libcerf-dev \
    texi2html \

    

RUN git clone https://github.com/openxm-org/OpenXM
RUN git clone https://github.com/openxm-org/OpenXM_contrib2


WORKDIR /OpenXM/src
ENV PATH="/OpenXM/bin:${PATH}"
# ↓は意味があったら残す
# #10 359.8 mkdir work
# 10 359.8 mkdir: cannot create directory 'work': File exists
# 10 359.8 make[1]: [Makefile:17: fetch] Error 1 (ignored)
# 10 359.8 if [ ! -f work/.configure_done ]; then \
# 10 359.8 	prefix=`cd ../..; pwd` ; \
# 10 359.8 	(cd work/gnuplot-5.4.0 ; ./configure --with-x --prefix="$prefix" --without-pdf) ; \
# 10 359.8 fi
# 10 359.9 configure: WARNING: unrecognized options: --without-pdf
# 10 359.9 ./configure: line 2703: 0: command not found
# を解決するために、一旦 work ディレクトリを削除してから configure を実行する
RUN rm -rf work
RUN make configure
RUN make install

WORKDIR /OpenXM/rc
RUN make && mkdir ~/bin && cp openxm ~/bin


CMD ["/bin/bash"]
