/etc/init.d/apt-cacher-ng start
export http_proxy=http://localhost:3142/

lb clean
lb build
