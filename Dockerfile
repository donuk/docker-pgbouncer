FROM percona/percona-pgbouncer:1.25.2

# Add custom entrypoint script
COPY --chown=pgbouncer:pgbouncer entrypoint-wrapper.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

# Add fixconfig-and-run script
COPY --chown=pgbouncer:pgbouncer fixconfig-and-run.sh /fixconfig-and-run.sh
RUN chmod +x /fixconfig-and-run.sh

ENTRYPOINT ["/entrypoint-wrapper.sh"]
CMD ["/usr/bin/pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]
