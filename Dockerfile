FROM clashclanvn/firstimage:latest
RUN mkdir -p /opt/scripts
RUN mkdir -p /opt/scripts1
RUN mkdir -p /opt/scripts2
COPY check_symbol_rate.sh /opt/scripts/



