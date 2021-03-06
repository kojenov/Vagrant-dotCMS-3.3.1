#!/bin/bash
updateRepos="true"
downloadApps="true"
unzipApps="true"
installOracleJDK8="true"
installMySQL="true"

version="3.3.1"
dotCMSDownloadURL="https://dotcms.com/physical_downloads/release_builds/dotcms_$version.tar.gz"

if  [ "$updateRepos" = "true" ]; then
	echo 'Updating repos'
	apt-get update
	echo 'Finished updating repos'
fi

if [ "$installOracleJDK8" = "true" ]; then
	echo "Installing Java"
	add-apt-repository ppa:webupd8team/java
	apt-get update
	echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
	apt-get -y install oracle-java8-installer
fi

if [ "$downloadApps" = "true" ]; then
	echo "Downloading Apps..."
	mkdir /downloadedApps
	cd /downloadedApps
  if [ ! -f dotcms_$version.tar.gz ]; then
	  wget -cN --progress=bar:force ${dotCMSDownloadURL}
  fi
fi

if [ "$unzipApps" = "true" ]; then
	echo "Unzipping apps"
	cd /downloadedApps
  if [ ! -d dotcms-$version ]; then
	  mkdir dotcms-$version
    cd dotcms-$version
    tar xzf ../dotcms_$version.tar.gz
  fi
fi

if [ "$installMySQL" = "true" ]; then
	echo "Installing MySQL"
	debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
	debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
	apt-get -y install mysql-server
	apt-get -y install mysql-client

	echo "Setting up MySQL"
	if ! grep "lower_case_table_names=1" /etc/mysql/my.cnf ; then
	sed -i '/\[mysqld\]/alower_case_table_names=1' /etc/mysql/my.cnf
	service mysql restart
	fi

	echo "Configuring dotCMS to use MySQL"
	echo 'create database dotcms default character set = utf8 default collate = utf8_general_ci;' | mysql --password=root
	# necessary updates in context.xml
	cd /downloadedApps/dotcms-3.?.*/dotserver/tomcat-8.?.*/webapps/ROOT/META-INF
	cat context.xml | sed '29s/-->//' | sed '37s/^.*$/ -->/' | sed '47s/$/ -->/' | sed '54s/^.*$//' | sed '50s/dotcms2/dotcms/' | sed '51s/{your db user}/root/' | sed '51s/{your db password}/root/' > context.tmp
	mv context.tmp context.xml
fi

#  Not necessary for most installations
sed -i  's/port="8080"/port="9999"/' /downloadedApps/dotcms-3.?.*/dotserver/tomcat-8.?.*/conf/server.xml #change the tomcat port
#sed -i  's/Host name="localhost"/Host name="myHost"/' /downloadedApps/dotcms-3.?.*/dotserver/tomcat-8.?.*/conf/server.xml #update hostname for this tomcat instance

#echo "starting dotCMS"
#Handled in the Vagrantfile
#/downloadedApps/dotcms-3.?.*/bin/startup.sh

echo ''
echo 'IN A FEW MINUTES, dotCMS will be accessible at http://localhost:9999/ (from your host)'
echo '===== Application Credentials ====='
echo ''
echo '=== Admin ==='
echo '     URL: http://localhost:9999/admin'
echo 'username: admin@dotcms.com'
echo 'password: admin'
echo ''
echo '=== Intranet User ==='
echo 'username: bill@dotcms.com'
echo 'password: bill'
echo ''
echo '=== Limited User ==='
echo 'username: joe@dotcms.com'
echo 'password: joe'
echo '===== Application Credentials ====='
echo 'Script finished.'
