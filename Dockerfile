FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

# 安装用到的软件
RUN /usr/bin/apt-get update && \
	/usr/bin/apt-get install -y curl && \
	curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
	/usr/bin/apt-get update && \
	/usr/bin/apt-get upgrade -y && \
	/usr/bin/apt-get install -y nodejs pulseaudio xvfb firefox ffmpeg xdotool unzip x11vnc

# 安装中文字体
RUN set -eux && \
    apt-get update && \
    apt-get install -y locales tzdata xfonts-wqy ttf-wqy-microhei ttf-wqy-zenhei && \
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    find /var/lib/apt/lists -type f -delete && \
    find /var/cache -type f -delete

# 配置中文
ENV LANG=zh_CN.UTF-8 LANGUAGE=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8

# 配置firefox

COPY resource/h264 /tmp/h264

COPY /recording /recording
WORKDIR /recording
RUN chmod +x /recording/*.sh
# RUN /usr/bin/npm install

EXPOSE 80 5900

ENTRYPOINT ["/recording/run.sh"]