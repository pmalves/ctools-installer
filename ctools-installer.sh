#!/bin/bash

echo
echo CTOOLS
echo
echo ctools-installer version 1.7
echo 
echo "Author: Pedro Alves (webdetails)"
echo Thanks to Analytical Labs for jenkins builds
echo Copyright Webdetails 2011
echo
echo 
echo Changelog:
echo
echo v1.7 - Changed url locations to new path of analytical labs
echo v1.6 - Changed saiku download path to 2.1
echo v1.5 - Changed default indicator values in prompts
echo v1.4 - Added Saiku for the list of installs
echo v1.3 - Added support for automatic updates
echo v1.2 - Silent mode for downloading
echo v1.1 - Minor bugfixes
echo v1.0 - First release
echo
echo
echo "Disclaimer: we can't be responsible for any damage done to your system, which hopefully will not happen"
echo Note: ctools-installer.sh will upgrade the plugins under system directory.
echo "      Any changes you have made there (eg: cdf templates) will have to be backed up and manually copied after running the script"

INSTALLER=$0

# Checking for a new version
rm -rf .tmp
mkdir -p .tmp/dist

wget --no-check-certificate 'https://raw.github.com/pmalves/ctools-installer/master/ctools-installer.sh' -P .tmp -o /dev/null

if ! diff $0 .tmp/ctools-installer.sh >/dev/null ; then
  echo
  echo -n "There a new ctools-installer verison available. Do you want to upgrade? (y/N) "
  read -e answer

  case $answer in
    [Yy]* ) cp .tmp/ctools-installer.sh $0; echo "Upgrade successfull. Rerun"; exit 0;;
  esac

fi



SOLUTION_DIR=$1

if [[ $SOLUTION_DIR == "" ]]
then
	echo Please pass a path. Syntax: ctools-installer.sh /path/to/pentaho-solutions
	exit 1;
fi

if [[ ! -d $SOLUTION_DIR ]]
then
	echo File is not a directory
	exit 1;
fi

if [[ ! -d $SOLUTION_DIR/system ]]
then
	echo File is not a directory
	exit 1;
fi

#cd $SOLUTION_DIR

# downloading files

echo
echo Downloading files
echo


# CDF
wget --no-check-certificate http://ci.analytical-labs.com/job/Webdetails-CDF/lastSuccessfulBuild/artifact/bi-platform-v2-plugin/dist/pentaho-cdf-TRUNK-SNAPSHOT.zip -P .tmp/dist/ -o /dev/null


# CDA
wget --no-check-certificate 'http://ci.analytical-labs.com/job/Webdetails-CDA/lastSuccessfulBuild/artifact/dist/*zip*/dist.zip' -P .tmp/cda -o /dev/null
unzip .tmp/cda/dist.zip -d .tmp > /dev/null


# CDE
wget --no-check-certificate 'http://ci.analytical-labs.com/job/Webdetails-CDE/lastSuccessfulBuild/artifact/server/plugin/dist/*zip*/dist.zip' -P .tmp/cde -o /dev/null
unzip .tmp/cde/dist.zip -d .tmp > /dev/null


# SAIKU

#wget --no-check-certificate 'http://ci.analytical-labs.com/job/saiku-plugin/lastSuccessfulBuild/artifact/saiku-bi-platform-plugin/target/saiku-plugin-*zip*/*zip*/target.zip' -P .tmp/saiku -o /dev/null
#unzip .tmp/saiku/target.zip -d .tmp > /dev/null
# tamporarily switch for 2.1
wget --no-check-certificate 'http://analytical-labs.com/downloads/saiku-plugin-2.1.zip' -P .tmp -o /dev/null

echo
echo -n "Installing CDA. This will delete everything in $SOLUTION_DIR/system/cda. you sure? (y/N) "
read -e answer

case $answer in
  [Yy]* ) ;;
  * ) echo Quitting; exit 1;;
esac

rm -rf $SOLUTION_DIR/system/cda
rm -rf $SOLUTION_DIR/bi-developers/cda
unzip  .tmp/dist/cda-TRUNK-*zip -d $SOLUTION_DIR/system/ > /dev/null
unzip  .tmp/dist/cda-samples-TRUNK-*zip -d $SOLUTION_DIR/ > /dev/null

echo
echo -n "Installing CDE. This will delete everything in $SOLUTION_DIR/system/pentaho-cdf-dd. you sure? (y/N) "
read -e answer

case $answer in
  [Yy]* ) ;;
  * ) echo Quitting; exit 1;;
esac

rm -rf $SOLUTION_DIR/system/pentaho-cdf-dd
rm -rf $SOLUTION_DIR/cde_sample
unzip  .tmp/dist/pentaho-cdf-dd-TRUNK-*zip -d $SOLUTION_DIR/system/ > /dev/null
unzip  .tmp/dist/pentaho-cdf-dd-solution-TRUNK-*zip -d $SOLUTION_DIR/ > /dev/null

echo
echo -n "Installing CDF. This will delete everything in $SOLUTION_DIR/system/pentaho-cdf. you sure? (y/N) "
read -e answer

case $answer in
  [Yy]* ) ;;
  * ) echo Quitting; exit 1;;
esac

rm -rf $SOLUTION_DIR/system/pentaho-cdf
unzip  .tmp/dist/pentaho-cdf-TRUNK-*zip -d $SOLUTION_DIR/system/ > /dev/null

echo
echo -n "Installing Saiku. This will delete everything in $SOLUTION_DIR/system/saiku. you sure? (y/N) "
read -e answer

case $answer in
  [Yy]* ) ;;
  * ) echo Quitting; exit 1;;
esac

rm -rf $SOLUTION_DIR/system/saiku
unzip  .tmp/saiku-plugin*zip -d $SOLUTION_DIR/system/ > /dev/null

rm -rf .tmp

echo
echo Done!
echo
