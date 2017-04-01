FROM haskell:8
MAINTAINER Jan Philip Bernius <janphilip@bernius.net>

# Set to Non-Interactive
ENV DEBIAN_FRONTEND noninteractive

# Install all TeX and LaTeX dependences
RUN apt-get update && \
    apt-get install --yes --no-install-recommends apt-utils && \ 
    apt-get install --yes --no-install-recommends \
            make \
            git \
            wget \
            apt-transport-https \
            lsb-release \
            ca-certificates \
            locales \
            lmodern \
            texlive-latex-base \
            texlive-fonts-recommended \
            texlive-generic-recommended \
            texlive-lang-english \
            texlive-lang-german \
            latex-xcolor \
            texlive-math-extra \
            texlive-latex-extra \
            texlive-bibtex-extra \
            biber \
            fontconfig \
            texlive-xetex && \
  apt-get autoclean && \
  apt-get --purge --yes autoremove && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install PHP
RUN  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
     echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list && \
     apt-get update && \
     apt-get install --yes --no-install-recommends \
                     php7.1 \
                     php7.1-curl \
                     php7.1-zip \
                     php7.1-xml && \
     apt-get autoclean && \
     apt-get --purge --yes autoremove && \
     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

# Install Pandoc
RUN cabal update && cabal install \
  pandoc \
  pandoc-citeproc \
  pandoc-citeproc-preamble \
  pandoc-crossref

# Install kindelgen
RUN wget -O /tmp/kindlegen.tar.gz https://kindlegen.s3.amazonaws.com/kindlegen_linux_2.6_i386_v2_9.tar.gz && \
    cd /tmp && \
    tar -zxvf kindlegen.tar.gz && \
    mv /tmp/kindlegen /usr/local/bin && \
    cd ~ && \
    rm -rf /tmp/* 

# Set the locale
RUN dpkg-reconfigure locales
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Export the output data
WORKDIR /data
VOLUME ["/data"]

ENTRYPOINT ["pandoc"]

CMD ["--help"]
