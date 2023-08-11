#!/usr/bin/env bash

if [[ -f "/etc/debian_version" || -f "/etc/lsb-release" ]]
then
   echo "*** Installing dependencies for Ubuntu/Debian/Kali..."
   sudo apt-get install cpanminus libmojolicious-perl libtie-ixhash-perl
   sudo apt-get install liblwp-protocol-https-perl libjson-xs-perl libfile-slurp-perl
   sudo apt-get install libregexp-ipv6-perl libtext-csv-xs-perl
   sudo cpanm -n Config::INI::Tiny Text::ParseWords Net::IPv4Addr Regexp::IPv4
   echo "*** Installing dependencies for Ubuntu/Debian/Kali...done"
   echo ''
   echo "*** Installing ONYPHE CLI Perl module..."
   perl Build.PL
   ./Build && ./Build test
   sudo ./Build install
   echo "*** Installing ONYPHE CLI Perl module...done"
   echo ''
   echo '*** ONE MORE STEP: configure your ~/.onyphe.ini file as described in README file'
else
   echo "*** System unknown, can't install:"
   echo 'Please proceed with manual install as described in README file'
fi

exit 0
