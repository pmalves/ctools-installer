#!/bin/bash

echo
echo CTOOLS
echo
echo ctools-installer version 1.2
echo 
echo "Author: Pedro Alves (webdetails)"
echo Thanks to Analytical Labs for jenkins builds
echo Copyright Webdetails 2011
echo
echo "Disclaimer: we can't be responsible for any damage done to your system, which hopefully will not happen"
echo Note: ctools-installer.sh will upgrade the plugins under system directory.
echo "      Any changes you have made there (eg: cdf templates) will have to be backed up and manually copied after running the script"

INSTALLER=$0

# Checking for a new version
rm -rf .tmp
mkdir -p .tmp/dist

wget 'https://raw.github.com/pmalves/ctools-installer/master/ctools-installer.sh' -P .tmp -o /dev/null

if ! diff $0 .tmp/ctools-installer.sh >/dev/null ; then
  echo
  echo There a new ctools-installer verison available. Do you want to upgrade? [nY]
  echo 
  read -e answer

  if [[ $answer == "Y" ]]
  then
  	cp .tmp/ctools-installer.sh $0
  	echo Upgrade successfull. Rerun
  	exit 0
  fi

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
wget http://ci.analytical-labs.com/jenkins/job/Webdetails-CDF/lastSuccessfulBuild/artifact/bi-platform-v2-plugin/dist/pentaho-cdf-TRUNK-SNAPSHOT.zip -P .tmp/dist/ -o /dev/null


# CDA
wget 'http://ci.analytical-labs.com/jenkins/job/Webdetails-CDA/lastSuccessfulBuild/artifact/dist/*zip*/dist.zip' -P .tmp/cda -o /dev/null
unzip .tmp/cda/dist.zip -d .tmp > /dev/null


# CDE
wget 'http://ci.analytical-labs.com/jenkins/job/Webdetails-CDE/lastSuccessfulBuild/artifact/server/plugin/dist/*zip*/dist.zip' -P .tmp/cde -o /dev/null
unzip .tmp/cde/dist.zip -d .tmp > /dev/null


echo
echo Installing CDA. This will delete everything in $SOLUTION_DIR/system/cda. you sure? [n/Y]
echo
read -e answer

if [[ $answer != "Y" ]]
then
	echo Quitting
	exit 1
fi

rm -rf $SOLUTION_DIR/system/cda
rm -rf $SOLUTION_DIR/bi-developers/cda
unzip  .tmp/dist/cda-TRUNK-*zip -d $SOLUTION_DIR/system/
unzip  .tmp/dist/cda-samples-TRUNK-*zip -d $SOLUTION_DIR/


echo
echo Installing CDE. This will delete everything in $SOLUTION_DIR/system/pentaho-cdf-dd. you sure? [n/Y]
echo
read -e answer

if [[ $answer != "Y" ]]
then
	echo Quitting
	exit 1
fi

rm -rf $SOLUTION_DIR/system/pentaho-cdf-dd
rm -rf $SOLUTION_DIR/cde_sample
unzip  .tmp/dist/pentaho-cdf-dd-TRUNK-*zip -d $SOLUTION_DIR/system/
unzip  .tmp/dist/pentaho-cdf-dd-solution-TRUNK-*zip -d $SOLUTION_DIR/


echo
echo Installing CDF. This will delete everything in $SOLUTION_DIR/system/pentaho-cdf. you sure? [n/Y]
echo
read -e answer

if [[ $answer != "Y" ]]
then
	echo Quitting
	exit 1
fi

rm -rf $SOLUTION_DIR/system/pentaho-cdf
unzip  .tmp/dist/pentaho-cdf-TRUNK-*zip -d $SOLUTION_DIR/system/

rm -rf .tmp


echo
echo Done!
echo
