#!/bin/sh

test_method='aes-128-gcm aes-256-gcm chacha20-ietf chacha20-ietf-poly1305 rc4-md5 xchacha20-ietf-poly1305'

gen_ss_json(){
	cat <<-EOF > $PWD/ss.json
	{
	  "server":"127.0.0.1",
	  "server_port":8388,
	  "local_port":1080,
	  "password":"password",
	  "timeout":300,
	  "method":"$1",
	  "reuse_port":true
	}
	EOF
}

main(){
    set -x
    dd if=/dev/zero of=/var/www/html/test.img bs=1M count=1024
    for method in $test_method
    do
        gen_ss_json $method
        ss-server -c $PWD/ss.json >/dev/null 2>&1 &
        ss-local -c  $PWD/ss.json >/dev/null 2>&1 &
        curl --socks5 127.0.0.1 127.0.0.1/test.img -o /dev/null 2>&1 | tee $PWD/${method}_curl_info
        killall ss-server ss-local
    done
    set +x
    echo
    echo -----------------RESULT-----------------
    for method in $test_method
    do
        echo "          Method $method speed: `cat ${method}_curl_info |grep '100'|awk -F ' ' '{print $(NF-5)}'`"
    done
    echo -----------------RESULT-----------------
    echo
    set -x
    rm -f /var/www/html/test.img $PWD/ss.json $PWD/*curl_info
}

apt install nginx shadowsocks-libev

main
