#!/bin/bash
#===============================================================================================
#   System Required:  Debian or Ubuntu (32bit/64bit)
#   Description:  Install lnmp for Debian or Ubuntu
#   Author: tennfy <admin@tennfy.com>
#   Intro:  http://www.tennfy.com
#===============================================================================================
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear
echo "#############################################################"
echo "# Install lnmp for Debian or Ubuntu (32bit/64bit)"
echo "# Intro: http://www.tennfy.com"
echo "#"
echo "# Author: tennfy <admin@tennfy.com>"
echo "#"
echo "#############################################################"
echo ""

#Variables
lnmpdir='/opt/lnmp'
Ramthreshold='512'
ZendOpcache=''
Memcached=''
php_version=''
MysqlPass=''
SysName=''
SysBit=''
Cpunum=''
RamTotal=''
RamSwap=''
RamSum=''
StartDate=''
StartDateSecond=''
#color
CEND="\033[0m"
CMSG="\033[1;36m"
CFAILURE="\033[1;31m"
CSUCCESS="\033[32m"
CWARNING="\033[1;33m"

#Version
MysqlVersion='mysql-5.5.49'
PhpVersion='php-5.4.45'
NginxVersion='nginx-1.8.0'


function CheckSystem()
{
	[ $(id -u) != '0' ] && echo '[Error] Please use root to install lnmp' && exit
	egrep -i "centos" /etc/issue && SysName='centos'
	egrep -i "debian" /etc/issue && SysName='debian'
	egrep -i "ubuntu" /etc/issue && SysName='ubuntu'
	[ "$SysName" != 'debian'  ] && echo '[Error] Your system is not supported' && exit

	SysBit='32' && [ `getconf WORD_BIT` == '32' ] && [ `getconf LONG_BIT` == '64' ] && SysBit='64'
	Cpunum=`cat /proc/cpuinfo | grep 'processor' | wc -l`
	RamTotal=`free -m | grep 'Mem' | awk '{print $2}'`
	RamSwap=`free -m | grep 'Swap' | awk '{print $2}'`
	RamSum=$[$RamTotal+$RamSwap]
	echo '-----------------------------------------------------------------'
	echo "${SysBit}Bit, ${Cpunum}*CPU, ${RamTotal}MB*RAM, ${RamSwap}MB*Swap"	
	if [ "$RamSum" -lt "$Ramthreshold" ]
	then
	    echo 'Script will install mysql and php by apt-get'
		echo '-------------------------------------------------------------'
	else
	    echo 'Script will install mysql and php by compile'
		echo '-------------------------------------------------------------'
		#select php version
		while :
        do
            echo
            echo 'Please select php version:'
            echo -e "\t${CMSG}1${CEND}. Install PHP-5.4"
            echo -e "\t${CMSG}2${CEND}. Install PHP-5.5"
            echo -e "\t${CMSG}3${CEND}. Install PHP-5.6"
            read -p "Please input a number:(Default 1 press Enter) " php_version
            [ -z "$php_version" ] && php_version=1
            if [[ ! $php_version =~ ^[1-3]$ ]]
			then
                echo "${CWARNING}input error! Please only input number 1,2,3${CEND}"
            else
                if [ "$php_version" == '1' ]
				then
					PhpVersion='php-5.4.45'
				fi
				if [ "$php_version" == '2' ]
				then
					PhpVersion='php-5.5.30'
				fi
				if [ "$php_version" == '3' ]
				then
					PhpVersion='php-5.6.16'
			    fi
				break
            fi
		done
	fi	
	#select zendopcache
	while :
	do
		echo
		read -p "Do you want to install ZendOpcache? [y/n]: " ZendOpcache
		if [[ ! $ZendOpcache =~ ^[y,n]$ ]]
		then
			echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
		else
			break
		fi
	done
	#select memcached
	while :
	do
		echo
		read -p "Do you want to install Memcached? [y/n]: " memcached
		if [[ ! $memcached =~ ^[y,n]$ ]]
		then
			echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
		else
			break
		fi
	done
	#input mysql password
	InputMysqlPass		
	
}
function InputMysqlPass()
{
    echo
	read -p 'Please input MySQL password:' MysqlPass
	if [ "$MysqlPass" == '' ]
	then
		echo -e "${CFAILURE}[Error] MySQL password is empty.${CEND}"
		InputMysqlPass
	else
		echo -e "${CMSG}[OK] Your MySQL password is:$MysqlPass${CEND}"
	fi
}
function Timezone()
{
	rm -rf /etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

	echo '[ntp Installing] **************************************************** >>'
	apt-get install -y ntpdate
	ntpdate -u pool.ntp.org
	StartDate=$(date)
	StartDateSecond=$(date +%s)
	echo "Start time: ${StartDate}"
}
function CloseSelinux()
{
	[ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
}
function InstallLibiconv()
{
	if [ ! -d /usr/local/libiconv ]
	then
		#download libiconv
		wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
		tar -zxvf libiconv-1.14.tar.gz -C ${lnmpdir}/packages	
		cd ${lnmpdir}/packages/libiconv-1.14
		./configure --prefix=/usr/local/libiconv
		make
		make install
		cd /root
		rm -f libiconv-1.14.tar.gz
	fi
}
function Installcurl()
{
	if [ ! -d /usr/local/curl ]
	then
		#download curl
		wget http://curl.haxx.se/download/curl-7.46.0.tar.gz
		tar -zxvf curl-7.46.0.tar.gz -C ${lnmpdir}/packages	
		cd ${lnmpdir}/packages/curl-7.46.0
		./configure --prefix=/usr/local/curl
		make
		make install
		cd /root
		rm -f curl-7.46.0.tar.gz
	fi
}
function Installlibmcrypt()
{
	if [ ! -d /usr/local/libmcrypt ]
	then
		#download Libmcrypt
		wget http://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
		tar -zxvf libmcrypt-2.5.8.tar.gz -C ${lnmpdir}/packages
		cd ${lnmpdir}/packages/libmcrypt-2.5.8
		./configure --prefix=/usr/local/libmcrypt
		make
		make install
		cd /root
		rm -f libmcrypt-2.5.8.tar.gz
	fi
}
function Installmhash()
{
	if [ ! -d /usr/local/mhash ]
	then
		#download mhash
		wget http://downloads.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz
		tar -zxvf mhash-0.9.9.9.tar.gz -C ${lnmpdir}/packages
		cd ${lnmpdir}/packages/mhash-0.9.9.9
		./configure --prefix=/usr/local/mhash
		make
		make install
		cd /root
		rm -f mhash-0.9.9.9.tar.gz
	fi
}
function Installmcrypt()
{
	if [ ! -d /usr/local/mcrypt ]
	then	
		#download mcrypt
		wget http://downloads.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz
		tar -zxvf mcrypt-2.6.8.tar.gz -C ${lnmpdir}/packages
		cd ${lnmpdir}/packages/mcrypt-2.6.8
		ln -s /usr/local/libmcrypt/bin/libmcrypt-config   /usr/bin/libmcrypt-config  #添加软连接
        export LD_LIBRARY_PATH=/usr/local/mhash/lib:/usr/local/libmcrypt/lib
		export LDFLAGS="-L/usr/local/mhash/lib/ -I/usr/local/mhash/include/"
		export CFLAGS="-I/usr/local/mhash/include/"
		./configure --prefix=/usr/local/mcrypt
		make
		make install
		cd /root
		rm -f mcrypt-2.6.8.tar.gz
	fi
}
function remove_unneeded() 
{
	DEBIAN_FRONTEND=noninteractive apt-get -q -y remove --purge apache2* samba* bind9* nscd
	invoke-rc.d saslauthd stop
	invoke-rc.d xinetd stop
	update-rc.d saslauthd disable
	update-rc.d xinetd disable
	
	apt-get update
	for packages in build-essential gcc g++ cmake make ntp logrotate automake patch autoconf autoconf2.13 re2c wget flex cron libzip-dev libc6-dev rcconf bison cpp binutils tar bzip2 libncurses5-dev libncurses5 libtool libevent-dev libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlibc openssl libsasl2-dev libxml2 libxml2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libfreetype6 libfreetype6-dev libjpeg62 libjpeg62-dev libjpeg-dev libpng-dev libpng12-0 libpng12-dev libpq-dev libpq5 gettext libcap-dev ftp expect zip unzip git vim
	do
			echo "[${packages} Installing] ************************************************** >>"
			apt-get install -y $packages --force-yes;apt-get -fy install;apt-get -y autoremove
	done
}
function install_dotdeb() 
{
    if [ "$RamSum" -lt "$Ramthreshold" ]
	then
		echo -e 'deb http://packages.dotdeb.org stable all' >> /etc/apt/sources.list
		echo -e 'deb-src http://packages.dotdeb.org stable all' >> /etc/apt/sources.list
   
		#import GnuPG key
		wget http://www.dotdeb.org/dotdeb.gpg
		cat dotdeb.gpg | apt-key add -
		rm dotdeb.gpg
		apt-get update
	fi
}
function downloadfiles()
{	
	#download nginx
	wget http://nginx.org/download/${NginxVersion}.tar.gz
	tar -zxvf ${NginxVersion}.tar.gz -C ${lnmpdir}/packages
	#download phpmyadmin
	wget --no-check-certificate https://raw.githubusercontent.com/tennfy/debian_lnmp_tennfy/master/phpMyAdmin.tar.gz
	tar -zxvf phpMyAdmin.tar.gz -C ${lnmpdir}/packages
	#download configure files
	wget --no-check-certificate https://raw.githubusercontent.com/tennfy/debian_lnmp_tennfy/master/conf.tar.gz
	tar -zxvf conf.tar.gz -C ${lnmpdir}/conf
	#download nginx module
	git clone https://github.com/cuber/ngx_http_google_filter_module
    git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module
	cp -r ngx_http_google_filter_module ${lnmpdir}/packages/${NginxVersion}
	cp -r ngx_http_substitutions_filter_module ${lnmpdir}/packages/${NginxVersion}
	
	#delete all tar.gz packages
	rm *.tar.gz
	rm -r ngx_http_google_filter_module
	rm -r ngx_http_substitutions_filter_module
}
function zendopcache()
{   echo "----------------------------------------------------------------"
	echo "                begin to install zendopcache                    "
    echo "----------------------------------------------------------------" 
    if [ "$RamSum" -lt "$Ramthreshold" ]
	then
		apt-get install -y php-pear build-essential php5-dev
		pecl install zendopcache-7.0.5
		cat > /etc/php5/mods-available/opcache.ini<<EOF
[opcache]
zend_extension=/usr/lib/php5/20100525+lfs/opcache.so
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1
EOF
    
	    ln -s /etc/php5/mods-available/opcache.ini /etc/php5/conf.d/20-opcache.ini
	    apt-get --purge remove php5-dev
	else
		if [ "$php_version" == '1' ]
		then
			wget http://pecl.php.net/get/zendopcache-7.0.5.tgz
			tar xzf zendopcache-7.0.5.tgz -C ${lnmpdir}/packages
			cd ${lnmpdir}/packages/zendopcache-7.0.5
			/usr/local/php/bin/phpize
			./configure --with-php-config=/usr/local/php/bin/php-config
			make
			make install
			cat >> /etc/php5/php.ini<<EOF
[opcache]
zend_extension="`/usr/local/php/bin/php-config --extension-dir`/opcache.so"
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1
EOF
			 
			cd /root
			rm -f zendopcache-7.0.5.tgz
        else
		    cat >> /etc/php5/php.ini<<EOF
[opcache]
zend_extension="`/usr/local/php/bin/php-config --extension-dir`/opcache.so"
opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
EOF
		fi	   
    fi
	/etc/init.d/php5-fpm restart
	/etc/init.d/nginx restart
	echo "--------------------------------------------------------------"
	echo "                zendopcache install finished                  "
	echo "--------------------------------------------------------------"
}
function memcached()
{   echo "----------------------------------------------------------------"
	echo "                begin to install memcached                    "
    echo "----------------------------------------------------------------" 
    if [ "$RamSum" -lt "$Ramthreshold" ]
	then
		apt-get install -y memcached php5-memcache php5-memcached
	else
		#install memcached server
		id -u memcached >/dev/null 2>&1
		[ $? -ne 0 ] && useradd -M -s /sbin/nologin memcached
		
		wget http://www.memcached.org/files/memcached-1.4.25.tar.gz
		tar xzf memcached-1.4.25.tar.gz -C ${lnmpdir}/packages
		cd ${lnmpdir}/packages/memcached-1.4.25 
		./configure --prefix=/usr/local/memcached   
		make && make install
		
		ln -s /usr/local/memcached/bin/memcached /usr/bin/memcached	
		cp 	${lnmpdir}/conf/memcached /etc/init.d/memcached
		chmod +x /etc/init.d/memcached
		update-rc.d memcached defaults
		/etc/init.d/memcached start
		cd /root	
		rm -f memcached-1.4.25.tar.gz
		
		#install php-memcache
		wget http://pecl.php.net/get/memcache-3.0.8.tgz
		tar xzf memcache-3.0.8.tgz -C ${lnmpdir}/packages
		cd ${lnmpdir}/packages/memcache-3.0.8
		/usr/local/php/bin/phpize
		./configure --with-php-config=/usr/local/php/bin/php-config
		make && make install
		
        sed -i 's#^extension_dir\(.*\)#extension_dir\1\nextension = "memcache.so"#g' /etc/php5/php.ini	
		cd /root	
		rm -f memcache-3.0.8.tgz
		
        #install php-memcached
		wget https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz
		tar xzf libmemcached-1.0.18.tar.gz -C ${lnmpdir}/packages
		cd ${lnmpdir}/packages/libmemcached-1.0.18
		sed -i "s#lthread -pthread -pthreads#lthread -lpthread -pthreads#g" ./configure
		./configure --with-memcached=/usr/local/memcached  
		make && make install
		cd /root
		rm -f libmemcached-1.0.18.tar.gz
		 
		wget http://pecl.php.net/get/memcached-2.2.0.tgz
		tar xzf memcached-2.2.0.tgz	-C ${lnmpdir}/packages
		cd ${lnmpdir}/packages/memcached-2.2.0
		/usr/local/php/bin/phpize
		./configure --with-php-config=/usr/local/php/bin/php-config
		make && make install
		
		sed -i 's#^extension_dir\(.*\)#extension_dir\1\nextension = "memcached.so"#g' /etc/php5/php.ini	
		cd /root	
		rm -f memcached-2.2.0.tgz
    fi
	/etc/init.d/php5-fpm restart
	/etc/init.d/nginx restart
	echo "--------------------------------------------------------------"
	echo "                memcached install finished                    "
	echo "--------------------------------------------------------------"
}
function installmysql()
{
    echo "----------------------------------------------------------------"
	echo "                     begin to install mysql                     "
    echo "----------------------------------------------------------------" 
	if [ "$RamSum" -lt "$Ramthreshold" ]
	then
	    #install mysql
		debconf-set-selections <<< "mysql-server mysql-server/root_password password $MysqlPass"
		debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MysqlPass"
		apt-get install -y mysql-client mysql-server
		# Install a low-end copy of the my.cnf to disable InnoDB
		/etc/init.d/mysql stop
		cp  ${lnmpdir}/conf/lowend.cnf /etc/mysql/conf.d/lowend.cnf 
	else
		if [ ! -d /usr/local/mysql ]
		then
			mkdir /var/lib/mysql /var/run/mysqld /etc/mysql /etc/mysql/conf.d
			#download mysql
			wget http://cdn.mysql.com//Downloads/MySQL-5.5/${MysqlVersion}.tar.gz
			tar -zxvf ${MysqlVersion}.tar.gz -C ${lnmpdir}/packages
			cd ${lnmpdir}/packages/${MysqlVersion}
			groupadd mysql
			useradd -s /sbin/nologin -g mysql mysql
			cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/var/lib/mysql -DMYSQL_TCP_PORT=3306 -DMYSQL_UNIX_ADDR=/var/run/mysqld/mysqld.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 
			make
			make install
			
			chmod +w /usr/local/mysql
			chown -R mysql:mysql /usr/local/mysql
			chown -R mysql /var/run/mysqld
			#add configuration file
			rm -f /etc/mysql/my.cnf /usr/local/mysql/etc/my.cnf
			cp ${lnmpdir}/conf/my.cnf /etc/mysql/my.cnf
			/usr/local/mysql/scripts/mysql_install_db --user=mysql --defaults-file=/etc/mysql/my.cnf --basedir=/usr/local/mysql --datadir=/var/lib/mysql
# EOF **********************************
cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
# **************************************
			ldconfig
			if [ "$SysBit" == '64' ] 
			then
				ln -s /usr/local/mysql/lib/mysql /usr/lib64/mysql
			else
				ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql
			fi
			chmod 775 /usr/local/mysql/support-files/mysql.server
            ln -s /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
			chmod +x /etc/init.d/mysql
			/etc/init.d/mysql start
			ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
			ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin
			ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
			ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
			ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe
			
			/usr/local/mysql/bin/mysqladmin password $MysqlPass
			rm -rf /var/lib/mysql/test

# EOF **********************************
mysql -hlocalhost -uroot -p$MysqlPass <<EOF
USE mysql;
DELETE FROM user WHERE User!='root' OR (User = 'root' AND Host != 'localhost');
UPDATE user set password=password('$MysqlPass') WHERE User='root';
DROP USER ''@'%';
FLUSH PRIVILEGES;
EOF
# **************************************
           /etc/init.d/mysql stop
		   update-rc.d mysql defaults
           cd /root	
		   rm -f ${MysqlVersion}.tar.gz		   
	    fi		
	fi
    /etc/init.d/mysql start
	echo "--------------------------------------------------------------"
	echo "                      mysql install finished                  "
	echo "--------------------------------------------------------------"
}
function installphp(){
    echo "--------------------------------------------------------------"
	echo "                      begin to install php                    "
    echo "--------------------------------------------------------------"  
    if [ "$RamSum" -lt "$Ramthreshold" ]
	then	
		apt-get -y install php5-fpm php5-gd php5-common php5-curl php5-imagick php5-mcrypt php5-mysql php5-cgi php5-cli 
		/etc/init.d/php5-fpm stop
		sed -i  s/'listen = 127.0.0.1:9000'/'listen = \/var\/run\/php5-fpm.sock'/ /etc/php5/fpm/pool.d/www.conf
		sed -i  s/'^pm.max_children = [0-9]*'/'pm.max_children = 2'/ /etc/php5/fpm/pool.d/www.conf
		sed -i  s/'^pm.start_servers = [0-9]*'/'pm.start_servers = 2'/ /etc/php5/fpm/pool.d/www.conf
		sed -i  s/'^pm.min_spare_servers = [0-9]*'/'pm.min_spare_servers = 2'/ /etc/php5/fpm/pool.d/www.conf
		sed -i  s/'^pm.max_spare_servers = [0-9]*'/'pm.max_spare_servers = 3'/ /etc/php5/fpm/pool.d/www.conf
		sed -i  s/'^pm.max_children = [0-9]*'/'pm.max_children = 3'/ /etc/php5/fpm/pool.d/www.conf
		sed -i  s/'memory_limit = 128M'/'memory_limit = 64M'/ /etc/php5/fpm/php.ini
		sed -i  s/'short_open_tag = Off'/'short_open_tag = On'/ /etc/php5/fpm/php.ini
		sed -i  s/'upload_max_filesize = 2M'/'upload_max_filesize = 16M'/ /etc/php5/fpm/php.ini    	
	else
	    #install curl
		Installcurl
		#install mcrypt
		Installlibmcrypt
		Installmhash
		Installmcrypt
	    #install Libiconv
		InstallLibiconv
		#install PHP
		if [ ! -d /usr/local/php ]
		then
			mkdir /etc/php5
			#download php
			wget http://php.net/distributions/${PhpVersion}.tar.gz
			tar -zxvf ${PhpVersion}.tar.gz -C ${lnmpdir}/packages
			cd ${lnmpdir}/packages/${PhpVersion}
			groupadd www-data
			useradd -m -s /sbin/nologin -g www-data www-data
			[ "$ZendOpcache" == 'y' ] && [ "$php_version" == '2' -o "$php_version" == '3' ] && PHP_cache_tmp='--enable-opcache' || PHP_cache_tmp=''  
			./configure --prefix=/usr/local/php --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --with-config-file-path=/etc/php5 --with-openssl --with-zlib  --with-curl=/usr/local/curl --enable-sockets --with-xmlrpc --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --without-pear --disable-fileinfo --with-mcrypt=/usr/local/libmcrypt $PHP_cache_tmp
			make
			make install
			
			#cp configuration file
			cp 	${lnmpdir}/conf/php.ini /etc/php5/php.ini
			sed -i "s#extension_dir = \"ext\"#extension_dir = \"`/usr/local/php/bin/php-config --extension-dir`\"#g" /etc/php5/php.ini
			cp 	${lnmpdir}/conf/php-fpm.conf /etc/php5/php-fpm.conf
			cp 	${lnmpdir}/conf/php5-fpm /etc/init.d/php5-fpm
			chmod +x /etc/init.d/php5-fpm
        
			ln -s /usr/local/php/bin/php /usr/bin/php
			ln -s /usr/local/php/bin/phpize /usr/bin/phpize
			ln -s /usr/local/php/sbin/php-fpm /usr/sbin/php5-fpm
			#php auto-start		
			update-rc.d php5-fpm defaults
			cd /root
			rm -f ${PhpVersion}.tar.gz
		fi
	fi
	/etc/init.d/php5-fpm start	
	echo "---------------------------------------------------------------"
	echo "                    php install finished                       "
    echo "---------------------------------------------------------------"	
}
function installnginx(){
    echo "---------------------------------------------------------------"
	echo "                      begin to install nginx                   "
    echo "---------------------------------------------------------------"
	#install nginx
	if [ ! -f /usr/sbin/nginx ]
	then
		cd ${lnmpdir}/packages/${NginxVersion}
		./configure --user=www-data --group=www-data --sbin-path=/usr/sbin/nginx --prefix=/etc/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_ssl_module  --with-http_gzip_static_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --without-http_uwsgi_module --without-http_scgi_module  --add-module=ngx_http_google_filter_module --add-module=ngx_http_substitutions_filter_module
		make
		make install
		cd /root
	# add conf.d dir
	if [ ! -d /etc/nginx/conf.d ]
	then
        mkdir /etc/nginx/conf.d
		if [ ! -d /var/www ]
	    then
			mkdir /var/www
		fi
	fi  
	#add nginx configuration file
	if [ -f /etc/nginx/nginx.conf ]
	then
	    rm /etc/nginx/nginx.conf	
        cp 	${lnmpdir}/conf/nginx.conf /etc/nginx/nginx.conf
        cp 	${lnmpdir}/conf/nginx /etc/init.d/nginx
		chmod +x /etc/nginx/nginx.conf
		chmod +x /etc/init.d/nginx
	fi	
	#set nginx auto-start
	ln -s /usr/sbin/nginx /usr/bin/nginx
	update-rc.d nginx defaults
	#add rewrite rule
	cp 	${lnmpdir}/conf/wordpress.conf /etc/nginx/wordpress.conf
	cp 	${lnmpdir}/conf/discuz.conf /etc/nginx/discuz.conf

	/etc/init.d/nginx start
		
	echo "---------------------------------------------------------------"
	echo "                   nginx install finished                      "
    echo "---------------------------------------------------------------"
	fi
}
function virtualhost(){
    echo "---------------------------------------------------------------"
	echo "           begin to install virtual host                       "
    echo "---------------------------------------------------------------"
	echo "please input hostname(like tennfy.com):"
	read hostname
	echo "please input url rewrite rule name(wordpress or discuz):"
	read rewriterule	
	#stop nginx
	/etc/init.d/nginx stop	
    #get nginx configure file template and edit
    cp  ${lnmpdir}/conf/host.conf /etc/nginx/conf.d
	mv /etc/nginx/conf.d/host.conf /etc/nginx/conf.d/${hostname}.conf
	sed -i 's/tennfy.com/'${hostname}'/g' /etc/nginx/conf.d/${hostname}.conf
	sed -i 's/rewriterule/'${rewriterule}'/g' /etc/nginx/conf.d/${hostname}.conf	
	#make a virtualhost dir
	mkdir /var/www/${hostname}
	cd /var/www/${hostname}
	chmod -R 777 /var/www
	chown -R www-data:www-data /var/www
	#add phpinfo file
	cat  >> /var/www/${hostname}/info.php <<EOF
	<?php phpinfo(); ?>
EOF

	/etc/init.d/nginx start
	echo -e "-----------------------------------------------------------" &&
	echo -e "   ${CSUCCESS}install virtual host successfully!${CEND}    " &&
	echo -e "-----------------------------------------------------------"
}
function sslvirtualhost(){
    echo "--------------------------------------------------------------"
	echo "           begin to install ssl virtual host                  "
    echo "--------------------------------------------------------------"
	echo "please input hostname(like tennfy.com):"
	read hostname
	echo "please input url rewrite rule name(wordpress or discuz):"
	read rewriterule	
	echo "please input ssl certificate file path:"
	read certificate
	echo "please input ssl privatekey file path:"
	read privatekey	
	#stop nginx
	/etc/init.d/nginx stop	
    #get nginx configure file template and edit
    cp  ${lnmpdir}/conf/sslhost.conf /etc/nginx/conf.d
	mv /etc/nginx/conf.d/sslhost.conf /etc/nginx/conf.d/${hostname}.conf
	sed -i 's/tennfy.com/'${hostname}'/g' /etc/nginx/conf.d/${hostname}.conf
	sed -i 's/rewriterule/'${rewriterule}'/g' /etc/nginx/conf.d/${hostname}.conf	
	sed -i 's#tennfy_certificate#'${certificate}'#g' /etc/nginx/conf.d/${hostname}.conf	
	sed -i 's#tennfy_privatekey#'${privatekey}'#g' /etc/nginx/conf.d/${hostname}.conf	
	#new a virtualhost dir
	mkdir /var/www/${hostname}
	cd /var/www/${hostname}
	chmod -R 777 /var/www
	chown -R www-data:www-data /var/www
	#add phpinfo file
	cat  >> /var/www/${hostname}/info.php <<EOF
	<?php phpinfo(); ?>
EOF

	/etc/init.d/nginx start
	echo -e "------------------------------------------------------------" &&
	echo -e "   ${CSUCCESS}install ssl virtual host successfully!${CEND} " &&
	echo -e "------------------------------------------------------------"
}
function googlereverse(){
	echo "---------------------------------------------------------------"
	echo "            begin to install google reverse proxy              "
    echo "---------------------------------------------------------------"
	echo "please input hostname(like tennfy.com):"
	read hostname
	echo "please input ssl certificate file path:"
	read certificate
	echo "please input ssl privatekey file path:"
	read privatekey	
	#stop nginx
	/etc/init.d/nginx stop	
    #get nginx configure file template and edit
    cp  ${lnmpdir}/conf/google.conf /etc/nginx/conf.d
	mv /etc/nginx/conf.d/google.conf /etc/nginx/conf.d/${hostname}.conf
	sed -i 's/tennfy.com/'${hostname}'/g' /etc/nginx/conf.d/${hostname}.conf
	sed -i 's#tennfy_certificate#'${certificate}'#g' /etc/nginx/conf.d/${hostname}.conf	
	sed -i 's#tennfy_privatekey#'${privatekey}'#g' /etc/nginx/conf.d/${hostname}.conf	
	/etc/init.d/nginx start
	echo -e "-------------------------------------------------------------" &&
	echo -e "${CSUCCESS}install google reverse proxy successfully!${CEND} " &&
	echo -e "-------------------------------------------------------------"
}
function init(){
    echo -e "-------------------------------------------------------------"
	echo -e "               begin to initialize system                    "
    echo -e "-------------------------------------------------------------"
	cd /root
    # create packages and conf directory
	if [ ! -d ${lnmpdir} ]
	then 
	    mkdir ${lnmpdir}
		mkdir ${lnmpdir}/packages
		mkdir ${lnmpdir}/conf
	fi
	CheckSystem
	remove_unneeded
	install_dotdeb
	Timezone
	CloseSelinux
	downloadfiles
	echo -e "------------------------------------------------------------" &&
	echo -e "     ${CSUCCESS}initialize system successfully!${CEND}      " &&
	echo -e "------------------------------------------------------------"
}
function installlnmp(){
    #init system
	init
	#install mysql, php, nginx
	installmysql
	installphp
	installnginx	
	#install extention
	[ "$ZendOpcache" == 'y' ] && zendopcache
	[ "$memcached" == 'y' ] && memcached
	#set web dir
	cp -r ${lnmpdir}/packages/phpMyAdmin /var/www 
	#restart lnmp
	echo -e "-------------------------------------------------------------" &&
	echo -e "                 begin to restart lnmp!                      " &&
	echo -e "-------------------------------------------------------------"	
	/etc/init.d/nginx restart
	/etc/init.d/php5-fpm restart
	/etc/init.d/mysql restart
	echo -e "-------------------------------------------------------------" &&
	echo -e "      ${CSUCCESS}lnmp install successfully!${CEND}           " &&
	echo -e "-------------------------------------------------------------"
	echo "Start time: ${StartDate}";
	echo "Completion time: $(date) (Use: $[($(date +%s)-StartDateSecond)/60] minute)";
}
function addvhost(){
    while :
    do
            echo
            echo 'Please select host type:'
            echo -e "\t${CMSG}1${CEND}. Install virtual host"
            echo -e "\t${CMSG}2${CEND}. Install SSL virtual host"
            echo -e "\t${CMSG}3${CEND}. Install google reverse proxy"
            read -p "Please input a number:(Default 1 press Enter) " host_type
            [ -z "$host_type" ] && host_type=1
            if [[ ! $host_type =~ ^[1-3]$ ]];then
                echo "${CWARNING}input error! Please only input number 1,2,3${CEND}"
            else
                if [ "$host_type" == '1' ]
				then
					virtualhost
				fi
				if [ "$host_type" == '2' ]
				then
					sslvirtualhost
				fi
				if [ "$host_type" == '3' ]
				then
					googlereverse
			    fi
				break
            fi
    done
}
function delvhost(){
    echo "--------------------------------------------------------------"
	echo "                   begin to delete host                       "
    echo "--------------------------------------------------------------"
	echo "please input hostname(like tennfy.com):"
	read hostname
	if [ -f /etc/nginx/conf.d/${hostname}.conf ]
	then
	    rm -f /etc/nginx/conf.d/${hostname}.conf
	fi
	if [ -d /var/www/${hostname} ]
	then 
	    rm -r /var/www/${hostname}
	fi
	/etc/init.d/nginx start
	echo -e "------------------------------------------------------------" &&
	echo -e "    ${CSUCCESS}delete virtual host successfully!${CEND}     " &&
	echo -e "------------------------------------------------------------"
}
function uninstalllnmp(){
    echo "--------------------------------------------------------------"
	echo "                   begin to uninstall lnmp                    "
    echo "--------------------------------------------------------------"
    #stop all 
	/etc/init.d/php5-fpm stop
	/etc/init.d/nginx stop
	/etc/init.d/mysql stop
	#delete all install files
	rm -rf /opt/lnmp
	#delete all virtual hosts
	rm -rf /var/www
	#uninstall nginx
	update-rc.d -f nginx remove
	rm -rf /etc/nginx /etc/init.d/nginx /var/log/nginx
	rm -f  /usr/sbin/nginx  /var/run/nginx.pid
	#uninstall php
	if [ ! -d /usr/local/php ]
	then 
		apt-get --purge remove php5-fpm php5-gd php5-common php5-curl php5-imagick php5-mcrypt php5-mysql php5-cgi php5-cli memcached php5-memcache php5-memcached
	else
		update-rc.d -f php5-fpm remove
        rm -rf /etc/php5 /usr/local/php /usr/local/libiconv /usr/local/curl /usr/local/mhash /usr/local/mcrypt /usr/local/libmcrypt /usr/local/libmcrypt
		rm -f /etc/init.d/php5-fpm /usr/bin/php /usr/bin/phpize /usr/sbin/php5-fpm /var/run/php5-fpm.sock /var/run/php5-fpm.pid /var/log/php5-fpm.log 	
		if [ -d /usr/local/memcached ]
		then
		    rm -rf /usr/local/memcached
		fi
	fi
	#usinstall mysql
	if [ ! -d /usr/local/mysql ]
	then 
	    apt-get --purge remove mysql-client mysql-server
	else
		update-rc.d -f mysql remove
		rm -rf /etc/mysql /usr/local/mysql /var/lib/mysql /var/run/mysqld 
		rm -f  /etc/init.d/mysql /usr/bin/mysql /usr/bin/mysqladmin /usr/bin/mysqldump /usr/bin/myisamchk /usr/bin/mysqld_safe /var/run/mysqld/mysqld.sock /etc/ld.so.conf.d/mysql.conf
	fi 	
	echo -e "------------------------------------------------------------" &&
	echo -e "    ${CSUCCESS}uninstall lnmp successfully!${CEND}          " &&
	echo -e "------------------------------------------------------------"
}
######################### Initialization ################################################
action=$1
[ -z $1 ] && action=install
case "$action" in
install)
    installlnmp
    ;;
addvhost)
    addvhost
    ;;
delvhost)
    delvhost
    ;;
uninstall)
    uninstalllnmp
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|addvhost|delvhost|uninstall}"
    ;;
esac
