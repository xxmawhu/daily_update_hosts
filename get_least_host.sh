

wget https://hosts.gitcdn.top/hosts.txt -O hosts >>/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "$(date) | ERROR download hosts fail!"
    exit 1
else
    echo "$(date) | download hosts success"
fi
