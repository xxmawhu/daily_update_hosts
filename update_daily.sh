current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
cd $current_dir
exec >>./log/$(basename ${BASH_SOURCE[0]}).$(date +"%Y%m%d" && mkdir -p log) 2>&1
bash get_least_host.sh
python ./update_hosts.py
sudo cp ./sys_hosts /etc/hosts
