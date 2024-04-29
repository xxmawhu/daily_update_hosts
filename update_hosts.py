def write_to_etc_hosts(input_hosts="hosts", out_hosts="sys_hosts"):
    begin_token = "# fetch-github-hosts begin"
    end_token = "# fetch-github-hosts end"
    content_lines = []
    _begin = 0
    _end = 0
    for line in open("/etc/hosts", 'r').read().splitlines():
        if begin_token in line:
            _begin = 1
        if _begin + _end == 1:
            continue
        content_lines.append(line)
    content = "\n".join(content_lines)
    new_hosts = open(input_hosts, 'r').read()
    if begin_token not in new_hosts:
        new_hosts = begin_token + "\n" + new_hosts
    if end_token not in new_hosts:
        new_hosts += "\n" + end_token
    content += new_hosts
    with open(out_hosts, 'w') as f:
        f.write(content)


if __name__ == "__main__":
    write_to_etc_hosts()
