current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
cd $current_dir
exec >>./log/$(basename ${BASH_SOURCE[0]}).$(date +"%Y%m%d" && mkdir -p log) 2>&1
source tool.sh
checkout_silently ./add_cront.py
checkout_silently find ./log/ -type f -mtime +7 -exec rm -rf {} +
checkout_silently git pull --rebase
checkout_silently wget https://hosts.gitcdn.top/hosts.txt -O hosts
checkout_silently python3 update_hosts.py
checkout_silently cp ./sys_hosts /etc/hosts
