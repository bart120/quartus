# Agent de simulation et d'analyse HDL : outils libres uniquement (environ 2 Go).
# Construction : docker build -t formation/hdl-sim images/hdl-sim
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8
RUN apt-get update && apt-get install -y --no-install-recommends \
      ghdl-gcc iverilog verilator yosys graphviz doxygen gcovr \
      make git curl ca-certificates python3 python3-venv \
      openjdk-21-jre-headless \
 && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir "vunit_hdl==4.7.*" "cocotb==1.9.*" pytest vsg
ENV PATH=/opt/venv/bin:$PATH
RUN git config --system --add safe.directory '*'
COPY jenkins-agent.sh /usr/local/bin/jenkins-agent.sh
RUN chmod +x /usr/local/bin/jenkins-agent.sh
WORKDIR /workspace
CMD ["/usr/local/bin/jenkins-agent.sh"]
