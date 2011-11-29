#!/bin/bash

INSTALLER=`basename "$0"`
VER='1.10'

echo
echo CTOOLS
echo
echo ctools-installer version $VER
echo 
echo "Author: Pedro Alves (webdetails)"
echo Thanks to Analytical Labs for jenkins builds
echo Copyright Webdetails 2011
echo
echo 
echo Changelog:
echo
echo v1.10 - Added support for Saiku trunk snapshots installations.
echo v1.9 - Added support for CDA stable \(release\) installations.
echo v1.8 - Added CGG\; Script refactor
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
echo "     CGG will need to change the server WEB-INF/lib too. Backup your server"
echo 


usage (){

	echo 
	echo Usage: ctools-installer.sh -s solutionPath -w pentahoWebapPath -b branch
	echo
	echo "-s    Solution path (eg: /biserver/pentaho-solutions)"
	echo "-w    Pentaho webapp server path (requiresd for cgg, eg: /biserver-ce/tomcat/webapps/pentaho)"
	echo "-b    Branch from where to get ctools, stable for release, dev for trunk. Default is stable"
	echo "-h    This help screen"
	echo
	exit 1
}

cleanup (){
	rm -rf .tmp
}


# Parse options

[ $# -gt 1 ] || usage


SOLUTION_DIR='PATH'				# Variable name
WEBAPP_PATH='PATH'					# Show all matches (y/n)?
HAS_WEBAPP_PATH=0
BRANCH='stable'

while [ $# -gt 0 ]
do
    case "$1" in
	--)	shift; break;;
	-s)	SOLUTION_DIR="$2"; shift;;
	-w)	WEBAPP_PATH="$2"; shift;;
	-b) BRANCH="$2"; shift;;
	--)	break;;
	-*|-h)	usage ;;
    esac
    shift
done

[ $SOLUTION_DIR = 'PATH' ] && usage

if [ $WEBAPP_PATH != 'PATH' ]
then 
HAS_WEBAPP_PATH=1
fi


if  [ $BRANCH != 'stable' ] && [ $BRANCH != 'dev' ]
then
	echo ERROR: Branch must either be stable or dev
	exit 1
fi

if [[ ! -d $SOLUTION_DIR ]]
then
	echo ERROR: Supplied solution path is not a directory
	exit 1
fi

if [[ ! -d $SOLUTION_DIR/system ]]
then
	echo ERROR: Supplied solution path doesn\'t look like a valid pentaho solutions directory
	exit 1
fi

if [[ $HAS_WEBAPP_PATH -eq 1 ]]
then
	if [[ ! -d $WEBAPP_PATH/WEB-INF/lib ]]
	then

		echo "ERROR: Supplied webapp path doesn\'t look like a valid web application - missing WEB-INF/lib"
		exit 1
	fi

fi

URL1='-release'
FILESUFIX='-??.??.??'
if [ $BRANCH = 'dev' ]
then
	URL1=''
	FILESUFIX='-TRUNK'
fi



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


# Define download functions

downloadCDF (){

	# CDF
	echo -n "Downloading CDF... "
	wget --no-check-certificate http://ci.analytical-labs.com/job/Webdetails-CDF/lastSuccessfulBuild/artifact/bi-platform-v2-plugin/dist/pentaho-cdf-TRUNK-SNAPSHOT.zip -P .tmp/dist/ -o /dev/null
	echo "Done"

}


downloadCDA (){
	# CDA
	URL='http://ci.analytical-labs.com/job/Webdetails-CDA'$URL1'/lastSuccessfulBuild/artifact/dist/*zip*/dist.zip'	
	echo -n "Downloading CDA... "
	wget --no-check-certificate $URL -P .tmp/cda -o /dev/null
	unzip .tmp/cda/dist.zip -d .tmp > /dev/null
	echo "Done"
}


downloadCDE (){
	# CDE
	echo -n "Downloading CDE... "
	wget --no-check-certificate 'http://ci.analytical-labs.com/job/Webdetails-CDE/lastSuccessfulBuild/artifact/server/plugin/dist/*zip*/dist.zip' -P .tmp/cde -o /dev/null
	unzip .tmp/cde/dist.zip -d .tmp > /dev/null
	echo "Done"
}

downloadCGG (){
	# CGG
	echo -n "Downloading CGG... "
	wget --no-check-certificate 'http://ci.analytical-labs.com/job/Webdetails-CGG/lastSuccessfulBuild/artifact/*zip*/archive.zip' -P .tmp/cgg -o /dev/null
	unzip .tmp/cgg/archive.zip -d .tmp > /dev/null
	echo "Done"
}

downloadSaiku (){
	# SAIKU

	echo -n "Downloading Saiku... "
	#
	#unzip .tmp/saiku/target.zip -d .tmp > /dev/null
	# tamporarily switch for 2.1
	if [ $BRANCH = 'dev' ]
	then
		wget --no-check-certificate 'http://ci.analytical-labs.com/job/saiku-plugin/lastSuccessfulBuild/artifact/saiku-bi-platform-plugin/target/*zip*/target.zip' -P .tmp/saiku -o /dev/null
		unzip .tmp/saiku/target.zip -d .tmp > /dev/null		
		mv .tmp/target/saiku-* .tmp	
	else
		wget --no-check-certificate 'http://analytical-labs.com/downloads/saiku-plugin-2.1.zip' -P .tmp -o /dev/null
	fi
	echo "Done"
}


# Define install functions

installCDF (){
	rm -rf $SOLUTION_DIR/system/pentaho-cdf
	unzip  .tmp/dist/pentaho-cdf-TRUNK-*zip -d $SOLUTION_DIR/system/ > /dev/null
}

installCDE (){
	rm -rf $SOLUTION_DIR/system/pentaho-cdf-dd
	rm -rf $SOLUTION_DIR/cde_sample
	unzip  .tmp/dist/pentaho-cdf-dd-TRUNK-*zip -d $SOLUTION_DIR/system/ > /dev/null
	unzip  .tmp/dist/pentaho-cdf-dd-solution-TRUNK-*zip -d $SOLUTION_DIR/ > /dev/null
}

installCDA (){

	rm -rf $SOLUTION_DIR/system/cda
	rm -rf $SOLUTION_DIR/bi-developers/cda
	unzip  .tmp/dist/cda$FILESUFIX*zip -d $SOLUTION_DIR/system/ > /dev/null
	unzip  .tmp/dist/cda-samples-*zip -d $SOLUTION_DIR/ > /dev/null
}

installCGG (){
	rm -rf $SOLUTION_DIR/system/cgg
	unzip  .tmp/archive/dist/cgg-*zip -d $SOLUTION_DIR/system/ > /dev/null

	# Changes to the server; 1 - delete batik; 2 - copy new one plus xml and fop
	LIB_DIR=$WEBAPP_PATH/WEB-INF/lib
	CGG_DIR=$SOLUTION_DIR/system/cgg/lib

	rm -rf $LIB_DIR/batik-* $LIB_DIR/xml-apis* $LIB_DIR/xmlgraphics*
	cp $CGG_DIR/batik-[^j]* $CGG_DIR/xml* $LIB_DIR
}

installSaiku (){

	rm -rf $SOLUTION_DIR/system/saiku
	unzip  .tmp/saiku-plugin*zip -d $SOLUTION_DIR/system/ > /dev/null	

}


# read options for stuff to download/install

INSTALL_CDF=0
INSTALL_CDA=0
INSTALL_CDE=0
INSTALL_CGG=0
INSTALL_SAIKU=0

echo
echo -n "Install CDF? This will delete everything in $SOLUTION_DIR/system/pentaho-cdf. you sure? (y/N) "
read -e answer

case $answer in
  [Yy]* ) INSTALL_CDF=1;;
  * ) ;;
esac


echo
echo -n "Install CDA? This will delete everything in $SOLUTION_DIR/system/cda. you sure? (y/N) "
read -e answer

case $answer in
  [Yy]* ) INSTALL_CDA=1;;
  * ) ;;
esac


echo
echo -n "Install CDE? This will delete everything in $SOLUTION_DIR/system/pentaho-cdf-dd. you sure? (y/N) "
read -e answer

case $answer in
  [Yy]* ) INSTALL_CDE=1;;
  * ) ;;
esac


if [[ $HAS_WEBAPP_PATH -eq 1 ]]
then
	echo
	echo -n "Install CGG? This will delete everything in $SOLUTION_DIR/system/cgg. you sure? (y/N) "
	read -e answer
	case $answer in
	  [Yy]* ) INSTALL_CGG=1;;
	  * ) ;;
	esac
else
	echo
	echo 'No webapp path provided, will not install CGG'
fi



echo
echo -n "Install Saiku? This will delete everything in $SOLUTION_DIR/system/saiku. you sure? (y/N) "
read -e answer

case $answer in
  [Yy]* ) INSTALL_SAIKU=1;;
  * ) ;;
esac


nothingToDo (){
	echo Nothing to do. Exiting
	cleanup
	exit 1
}

[ $INSTALL_CDF -ne 0 ] || [ $INSTALL_CDE -ne 0 ] || [ $INSTALL_CDA -ne 0 ] || [ $INSTALL_CGG -ne 0 ] || [ $INSTALL_SAIKU -ne 0 ] || nothingToDo


# downloading files

echo
echo Downloading files
echo


[ $INSTALL_CDF -eq 0 ] || downloadCDF
[ $INSTALL_CDA -eq 0 ] || downloadCDA
[ $INSTALL_CDE -eq 0 ] || downloadCDE
[ $INSTALL_CGG -eq 0 ] || downloadCGG
[ $INSTALL_SAIKU -eq 0 ] || downloadSaiku


# installing files

echo
echo Installing files
echo

[ $INSTALL_CDF -eq 0 ] || installCDF
[ $INSTALL_CDA -eq 0 ] || installCDA
[ $INSTALL_CDE -eq 0 ] || installCDE
[ $INSTALL_CGG -eq 0 ] || installCGG
[ $INSTALL_SAIKU -eq 0 ] || installSaiku



cleanup

echo
echo Done!
echo

exit 0
