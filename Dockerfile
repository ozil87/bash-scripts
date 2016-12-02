FROM clashclanvn/firstimage
RUN mkdir -p /opt/scripts
COPY check_symbol_rate.sh /opt/scripts/
