from generate import ubuntu

standard = "CIS"
version = "Debian_Linux_12"
exclude = ["6.2.3.6"]

ubuntu(standard=standard, version=version, exclude_audits=exclude, method="remote", ssh_info={
    "username": "regal",
    "password": "252005",
    "ip": "127.0.0.1",
    "port": 2222
})

