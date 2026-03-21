FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    \
    # ----- 最優先：ビルドそのものに必須 -----
    build-essential \
    autoconf \
    bison \
    flex \
    file \
    curl \
    git \
    pkg-config \
    \
    # ----- 数値計算・OpenXM 本体依存 -----
    libcerf2 \
    libcerf-dev \
    \
    # ----- 端末・UI・gnuplot 関連 -----
    libncurses5-dev \
    libncursesw5-dev \
    libncurses-dev \
    libtinfo-dev \
    xorg-dev \
    libreadline-dev \
    \
    # ----- gd（画像/texi2html/gnuplot 等で検出されがち）-----
    libgd-dev \
    libgd3 \
    libpng-dev \
    libjpeg-dev \
    \
    # ----- gnuplot 高品質描画（cairo / pango）-----
    libcairo2-dev \
    libpango1.0-dev \
    libglib2.0-dev \
    \
    # ----- gnuplot Qt 端末（GUI）-----
    qtbase5-dev \
    qttools5-dev \
    libqt5svg5-dev \
    \
    # ----- configure / doc 判定で必須になりがち -----
    texinfo \
    texi2html \
    sharutils \
    \
    # ----- TeX 検出・kpsexpand（最重要 TeX ユーティリティ） -----
    texlive-extra-utils \
    \
    # ----- LaTeX基本環境（doc 生成の最低ライン） -----
    texlive-latex-recommended \
    texlive-fonts-recommended \
    \
    # ----- LaTeX拡張（doc が途中で死ぬのを防ぐ） -----
    texlive-latex-extra \
    \
    # ----- XeTeX / Unicode（日本語・近代 LaTeX） -----
    texlive-xetex \
    texlive-lang-japanese \
    \
    # ----- LaTeX→HTML / 画像変換系 -----
    latex2html \
    ghostscript \
    netpbm \
    \
    # ----- 補助ツール -----
    nkf \
    default-jdk \
    \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN git clone https://github.com/openxm-org/OpenXM
RUN git clone https://github.com/openxm-org/OpenXM_contrib2


WORKDIR /OpenXM/src
ENV PATH="/OpenXM/bin:${PATH}"
RUN make configure
RUN make install

WORKDIR /OpenXM/rc
RUN make && mkdir ~/bin && cp openxm ~/bin

WORKDIR /
CMD ["/bin/bash"]
