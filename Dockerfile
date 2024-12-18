FROM seafileltd/seafile-mc:11.0.13-arm AS main
COPY start.py bootstrap.py /scripts/
COPY setup-seafile-mysql.py /opt/seafile/seafile-server-11.0.13/
RUN chmod +x /scripts/start.py && \
    chmod +x /scripts/bootstrap.py && \
    chmod +x /opt/seafile/seafile-server-11.0.13/setup-seafile-mysql.py
EXPOSE 80

CMD ["/sbin/my_init", "--", "/scripts/enterpoint.sh"]
