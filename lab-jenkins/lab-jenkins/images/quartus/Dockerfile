# Agent Quartus Prime Lite (MAX 10), mode batch, sans Questa (environ 10 Go).
# Placer d'abord dans images/quartus/installeur/ (voir LISEZMOI.txt) :
#   - QuartusLiteSetup-<version>-linux.run
#   - max10-<version>.qdz          (même version)
# Construction (BuildKit, par défaut avec Docker récent) :
#   docker build -t formation/quartus images/quartus
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8
RUN apt-get update && apt-get install -y --no-install-recommends \
      libglib2.0-0 libfontconfig1 libfreetype6 libx11-6 libxext6 libxrender1 libsm6 \
      libncurses5 libtinfo5 \
      make git curl ca-certificates python3 openjdk-21-jre-headless \
 && rm -rf /var/lib/apt/lists/*
# L'installeur est monté pendant la construction seulement : il ne grossit pas l'image.
# Il installe automatiquement le fichier .qdz posé à côté de lui.
RUN --mount=type=bind,source=installeur,target=/tmp/inst,rw \
    chmod +x /tmp/inst/QuartusLiteSetup-*-linux.run \
 && /tmp/inst/QuartusLiteSetup-*-linux.run --mode unattended --accept_eula 1 \
      --installdir /opt/intelFPGA_lite \
 && rm -rf /opt/intelFPGA_lite/uninstall /opt/intelFPGA_lite/logs
ENV PATH=/opt/intelFPGA_lite/quartus/bin:$PATH
RUN git config --system --add safe.directory '*'
COPY jenkins-agent.sh /usr/local/bin/jenkins-agent.sh
RUN chmod +x /usr/local/bin/jenkins-agent.sh
CMD ["/usr/local/bin/jenkins-agent.sh"]
