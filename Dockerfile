FROM seafileltd/seafile-mc:11.0.2-arm as main
COPY start.py bootstrap.py /scripts/
COPY setup-seafile-mysql.py /opt/seafile/seafile-server-11.0.2/
RUN chmod +x /scripts/start.py && \
    chmod +x /scripts/bootstrap.py && \
    chmod +x /opt/seafile/seafile-server-11.0.2/setup-seafile-mysql.py
EXPOSE 80

CMD ["/sbin/my_init", "--", "/scripts/enterpoint.sh"]
