#!/usr/bin/env bash

APIKEY=$1

if [[ -z $APIKEY ]]
then
   echo 'ERROR: please provide your API key as a parameter like:'
   echo './install.sh MY_API_KEY'
   exit 1
fi

if [[ -f "/etc/debian_version" || -f "/etc/lsb-release" ]]
then
   echo "*** Installing dependencies for Ubuntu/Debian/Kali..."
   sudo apt-get install cpanminus libmojolicious-perl libtie-ixhash-perl
   sudo apt-get install liblwp-protocol-https-perl libjson-xs-perl libfile-slurp-perl
   sudo apt-get install libregexp-ipv6-perl libtext-csv-xs-perl
   sudo cpanm -n Config::INI::Tiny Text::ParseWords Net::IPv4Addr Regexp::IPv4
   echo "*** Installing dependencies for Ubuntu/Debian/Kali...done"
   echo ''
   if [[ ! -f ~/.onyphe.ini ]]
   then
      echo "*** Creating .onyphe.ini squeleton..."
      echo '# General APIs:' > ~/.onyphe.ini
      echo 'api_endpoint = https://www.onyphe.io/api/v2' >> ~/.onyphe.ini
      echo "api_key = $APIKEY" >> ~/.onyphe.ini
      echo '' >> ~/.onyphe.ini
      echo '# Unrated General APIs option:' >> ~/.onyphe.ini
      echo '#api_unrated_endpoint = https://www.onyphe.io/unrated/api/v2' >> ~/.onyphe.ini
      echo '#api_unrated_email = youremail@yourdomain.lan' >> ~/.onyphe.ini
      echo '' >> ~/.onyphe.ini
      echo '# Ondemand APIs:' >> ~/.onyphe.ini
      echo 'api_ondemand_endpoint = https://www.onyphe.io/api/v3' >> ~/.onyphe.ini
      echo "api_ondemand_key = $APIKEY" >> ~/.onyphe.ini
      echo '' >> ~/.onyphe.ini
      echo '# ASD APIs:' >> ~/.onyphe.ini
      echo 'api_asd_endpoint = https://www.onyphe.io/api/v1' >> ~/.onyphe.ini
      echo "api_asd_key =  $APIKEY" >> ~/.onyphe.ini
      echo '' >> ~/.onyphe.ini
      echo '# Tunables:' >> ~/.onyphe.ini
      echo 'api_maxpage = 1000' >> ~/.onyphe.ini
      echo '#api_size = 100' >> ~/.onyphe.ini
      echo '#api_trackquery = 1' >> ~/.onyphe.ini
      echo '#api_calculated = 1' >> ~/.onyphe.ini
      echo '#api_keepalive = 0' >> ~/.onyphe.ini
      echo "*** Creating .onyphe.ini squeleton...done"
      echo ''
   fi
   echo "*** Installing ONYPHE CLI Perl module..."
   perl Build.PL
   ./Build && ./Build test
   sudo ./Build install
   echo "*** Installing ONYPHE CLI Perl module...done"
   echo ''
   echo 'Try the following query to verify everything works:'
   echo "onyphe -search 'category:datascan domain:example.com'"
else
   if [[ ! -f ~/.onyphe.ini ]]
   then
      echo "*** Creating .onyphe.ini squeleton..."
      echo '# General APIs:' > ~/.onyphe.ini
      echo 'api_endpoint = https://www.onyphe.io/api/v2' >> ~/.onyphe.ini
      echo "api_key = $APIKEY" >> ~/.onyphe.ini
      echo '' >> ~/.onyphe.ini
      echo '# Unrated General APIs option:' >> ~/.onyphe.ini
      echo '#api_unrated_endpoint = https://www.onyphe.io/unrated/api/v2' >> ~/.onyphe.ini
      echo '#api_unrated_email = youremail@yourdomain.lan' >> ~/.onyphe.ini
      echo '' >> ~/.onyphe.ini
      echo '# Ondemand APIs:' >> ~/.onyphe.ini
      echo 'api_ondemand_endpoint = https://www.onyphe.io/api/v3' >> ~/.onyphe.ini
      echo "api_ondemand_key = $APIKEY" >> ~/.onyphe.ini
      echo '' >> ~/.onyphe.ini
      echo '# ASD APIs:' >> ~/.onyphe.ini
      echo 'api_asd_endpoint = https://www.onyphe.io/api/v1' >> ~/.onyphe.ini
      echo "api_asd_key =  $APIKEY" >> ~/.onyphe.ini
      echo '' >> ~/.onyphe.ini
      echo '# Tunables:' >> ~/.onyphe.ini
      echo 'api_maxpage = 1000' >> ~/.onyphe.ini
      echo '#api_size = 100' >> ~/.onyphe.ini
      echo '#api_trackquery = 1' >> ~/.onyphe.ini
      echo '#api_calculated = 1' >> ~/.onyphe.ini
      echo '#api_keepalive = 0' >> ~/.onyphe.ini
      echo "*** Creating .onyphe.ini squeleton...done"
      echo ''
   fi
   echo "ERROR: System unknown, can't install automatically:"
   echo 'Please proceed with manual install as described in README file paragraph 2.'
fi

exit 0
