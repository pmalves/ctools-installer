#!/bin/bash

INSTALLER=`basename "$0"`
VER='1.47'

echo
echo CTOOLS
echo
echo ctools-installer version $VER
echo
echo "Author: Pedro Alves (webdetails)"
echo Thanks to Analytical Labs for jenkins builds
echo Copyright Webdetails 2011-2013
echo
echo
echo Changelog:
echo
echo v1.47 - Removed CDB installation
echo v1.46 - Added stable versions for Pentaho 5
echo v1.45 - Added Marketplace, CFR and Sparkl, currently on -b dev only
echo v1.44 - Added option -r to specify offline mode
echo v1.43 - Added option -c to specify ctools list to download - Thanks to Tom
echo v1.42 - Changed stable CGG download process
echo v1.41 - Changed dev CGG download process
echo v1.40 - Changed dev saiku download path
echo v1.39 - Changed saiku download path to 2.4
echo v1.38 - Added option -n for CBF integration
echo v1.37 - plugin-samples/cdv was not deleted. Fixed
echo v1.36 - CDV now installs samples too
echo v1.35 - Support for stable CDV, CDC and CDB installation
echo v1.34 - Support for CDV installation using -b dev switch
echo v1.33 - Added support for Saiku ad hoc stable \(release\) installations.
echo v1.32 - Added windows cr tolerance for this script\'s auto update
echo v1.31 - Support for CDB installation using -b dev switch
echo v1.30 - Support for CDC installation using -b dev switch
echo v1.29 - Changed saiku download path to 2.3
echo v1.28 - Support for CGG in 4.5, where webapp path is no longer required
echo v1.27 - Added support for CGG stable \( release \) installations.
echo v1.26 - -y flag now also works for ctools-installer update. ctools-installer update is now automated - Thanks to Mark Reid.
echo v1.25 - Removed overwrite, explicitly deleting marketplace definition
echo v1.24 - Added force overwrite to unzip to phase out overwrite confirmation
echo v1.23 - CDF trunk installation change due to js publish
echo v1.22 - Changed saiku download path to 2.2
echo v1.21 - Added support for CDE stable \(release\) installations.
echo v1.20 - CDF new samples location updated to stable installation.
echo v1.19 - Corrected installCDF and installCDE to remove samples dir before installing
echo v1.18 - CDA samples installation to plugin-samples also in stable mode.
echo v1.17 - Change to CDA and CDE samples installation. Now installs to folder plugin-samples instead of bi-developers \(for trunk snapshot only\).
echo v1.16 - Added support for CDC and Saiku-adhoc installation - for now only available in dev/trunk mode.
echo v1.15 - Change to CDF samples installation. Now installs to folder plugin-samples instead of bi-developers \(for trunk snapshot only\).
echo v1.14 - Added support for CDF stable \(release\) installations.
echo v1.13 - Fixed issue in CGG download
echo v1.12 - Fixed typo in -Y option
echo v1.11 - Added support for -y option \(assume yes\) - Thanks to Christian G. Warden
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
	echo "Usage: ctools-installer.sh -s solutionPath [-w pentahoWebapPath] [-b branch]"
	echo
	echo "-s    Solution path (eg: /biserver/pentaho-solutions)"
	echo "-w    Pentaho webapp server path (required for cgg on versions before 4.5. eg: /biserver-ce/tomcat/webapps/pentaho)"
	echo "-b    Branch from where to get ctools, stable for release, dev for trunk. Default is stable"
	echo "-c    Comma-separated list of CTools to install (Supported module-names: marketplace,cdf,cda,cde,cgg,cfr,sparkl,cdc,cdv,saiku,saikuadhoc)"
	echo "-y    Assume yes to all prompts"
	echo "--no-update Skip update of the ctools-installer.sh"
	echo "-n    Add newline to end of prompts (for integration with CBF)"
	echo "-r    Directory for storing offline files"
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
WEBAPP_PATH='PATH'				# Show all matches (y/n)?
HAS_WEBAPP_PATH=0
BRANCH='stable'
ECHO_FLAG='-n'
MODULES=''
ASSUME_YES=false
NO_UPDATE=false
OFFLINE_REPOSITORY=''
BASERVER_VERSION=''

ORIGINAL_CMDS=$@

while [ $# -gt 0 ]
do
    case "$1" in
	--)	shift; break;;
	-s)	SOLUTION_DIR="$2"; shift;;
	-w)	WEBAPP_PATH="$2"; shift;;
	-b) BRANCH="$2"; shift;;
	-c) MODULES="$2"; shift;;
	-y)	ASSUME_YES=true;;
	--no-update) NO_UPDATE=true;;
	-n)	ECHO_FLAG='';;
	-r) OFFLINE_REPOSITORY="$2"; shift;;
	--)	break;;
	-*|-h)	usage ;;
    esac
    shift
done

[ "$SOLUTION_DIR" = 'PATH' ] && usage

if [ "$WEBAPP_PATH" != 'PATH' ]
then
HAS_WEBAPP_PATH=1
fi


if  [ $BRANCH != 'stable' ] && [ $BRANCH != 'dev' ]
then
	echo ERROR: Branch must either be stable or dev
	exit 1
fi

if [[ ! -d "$SOLUTION_DIR" ]]
then
	echo ERROR: Supplied solution path is not a directory
	exit 1
fi

if [[ ! -d "$SOLUTION_DIR/system" ]]
then
	echo "ERROR: Supplied solution path doesn't look like a valid pentaho solutions directory.  Missing system sub-directory."
	exit 1
fi

if [[ $HAS_WEBAPP_PATH -eq 1 ]]
then
	if [[ ! -d $WEBAPP_PATH/WEB-INF/lib ]]
	then

		echo "ERROR: Supplied webapp path doesn't look like a valid web application - missing WEB-INF/lib"
		exit 1
	fi

fi

if [[ -d "$SOLUTION_DIR/system/jackrabbit" ]]
then
	BASERVER_VERSION='5x'
else
	BASERVER_VERSION='4x'
fi

if [ "$OFFLINE_REPOSITORY" != "" ]
then
	mkdir -p "$OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH"
	if [ $? != 0 ]; then
		echo "ERROR: Failed to create offline stage directory: $OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH"
		exit 1
	fi
fi

for reqcmd in zip unzip wget
do
  if [[ -z "$(which $reqcmd)" ]]
  then
    echo "ERROR: Missing required '$reqcmd' command."
    exit 1
  fi
done

# enable extended regexp matching
shopt -s extglob

if [ $BRANCH = 'dev' ]
then
	URL1=''
    FILESUFIX='-TRUNK-SNAPSHOT'
else
	URL1='-release'
    FILESUFIX='-+([0-9.])' # +([0-9.]) is an extended regexp. meaning match
                           # at least one of these items: [0-9.]
fi


# Checking for a new version
rm -rf .tmp
mkdir -p .tmp/dist

wget --no-check-certificate 'https://raw.github.com/pmalves/ctools-installer/master/ctools-installer.sh' -P .tmp -o /dev/null

if ! diff --strip-trailing-cr $0 .tmp/ctools-installer.sh >/dev/null ; then
  answer=n
  if $ASSUME_YES ; then
    answer=y
  elif $NO_UPDATE ; then
    answer=n
  else
    echo
    echo $ECHO_FLAG "There a new ctools-installer version available. Do you want to upgrade? (y/N) "
    read -e answer < /dev/tty
  fi

  case $answer in
	 [Yy]* ) cp .tmp/ctools-installer.sh $0; echo "Upgrade successful. Rerunning command '$0 $ORIGINAL_CMDS'"; /bin/bash $0 $ORIGINAL_CMDS; exit 0;;
  esac

fi

# Define download functions

download_file () {
	WGET_CTOOL="$1"
	WGET_URL="$2"
	WGET_FILE="$3"
	WGET_TARGET_DIR="$4"
	mkdir -p "$WGET_TARGET_DIR"
	if [ ! -z "$OFFLINE_REPOSITORY" -a -e "$OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH/$WGET_CTOOL/$WGET_FILE" ]; then
		echo $ECHO_FLAG "Found $WGET_CTOOL in offline repository. "
		cp "$OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH/$WGET_CTOOL/$WGET_FILE" "$WGET_TARGET_DIR"
	else
		echo $ECHO_FLAG "Downloading $WGET_CTOOL..."
		wget -q --no-check-certificate "$WGET_URL" -O "$WGET_TARGET_DIR/$WGET_FILE"
		if [ ! -z "$OFFLINE_REPOSITORY" ]; then
			echo $ECHO_FLAG " Storing $WGET_CTOOL in offline repository... "
			mkdir -p "$OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH/$WGET_CTOOL" ;
			cp "$WGET_TARGET_DIR/$WGET_FILE" "$OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH/$WGET_CTOOL/$WGET_FILE"
		fi
	fi
}

downloadMarketplace () {
	# Marktetplace
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
		URL='http://ci.pentaho.com/job/marketplace-4.8'$URL1'/lastSuccessfulBuild/artifact/dist/marketplace-plugin-TRUNK-SNAPSHOT.zip'
	else
		URL='http://ci.pentaho.com/job/marketplace'$URL1'/lastSuccessfulBuild/artifact/dist/marketplace-TRUNK-SNAPSHOT.zip'
	fi
	download_file "Marketplace"  "$URL"  "plugin.zip"  ".tmp/marketplace"
	rm -f .tmp/dist/marketplace.xml
	unzip -o .tmp/marketplace/plugin.zip -d .tmp > /dev/null
	chmod -R u+rwx .tmp
	echo "Done"
}

downloadCDF () {
	# CDF
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
	    if  [ $BRANCH = 'dev' ]
	    then
    		URL='http://ci.pentaho.com/job/pentaho-cdf-pentaho/lastSuccessfulBuild/artifact/cdf-pentaho/dist/*zip*/dist.zip'
    	else
    	  URL='http://www.webdetails.pt/ficheiros/cdf/14.12.10.1/4.x/dist.zip'
    	fi
	else
	    if  [ $BRANCH = 'dev' ]
	    then
		    URL='http://ci.pentaho.com/job/pentaho-cdf/lastSuccessfulBuild/artifact/cdf-pentaho5/dist/*zip*/dist.zip'
		else
            URL='http://www.webdetails.pt/ficheiros/cdf/14.12.10.1/5.x/dist.zip'
		fi
	fi
	download_file "CDF"  "$URL"  "dist.zip"  ".tmp/cdf"
	rm -f .tmp/dist/marketplace.xml
	unzip -o .tmp/cdf/dist.zip -d .tmp > /dev/null
	chmod -R u+rwx .tmp
	echo "Done"
}


downloadCDA (){
	# CDA
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
		if [ $BRANCH = 'dev' ]
		then
		    URL='http://ci.pentaho.com/job/pentaho-cda-pentaho/lastSuccessfulBuild/artifact/cda-pentaho/dist/*zip*/dist.zip'
	    else
	    	URL='http://www.webdetails.pt/ficheiros/cda/14.12.10/4.x/dist.zip'
	    fi
	else
		if [ $BRANCH = 'dev' ]
		then
    		URL='http://ci.pentaho.com/job/pentaho-cda/lastSuccessfulBuild/artifact/cda-pentaho5/dist/*zip*/dist.zip'
	    else
	    	URL='http://www.webdetails.pt/ficheiros/cda/14.12.10/5.x/dist.zip'
	    fi

	fi
	download_file "CDA"  "$URL"  "dist.zip"  ".tmp/cda"
	rm -f .tmp/dist/marketplace.xml
	unzip -o .tmp/cda/dist.zip  -d .tmp > /dev/null
	chmod -R u+rwx .tmp
	echo "Done"
}

downloadCDE (){
	# CDE
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
		if [ $BRANCH = 'dev' ]
		then
		    URL='http://ci.pentaho.com/job/pentaho-cde-pentaho/lastSuccessfulBuild/artifact/cde-pentaho/dist/*zip*/dist.zip'
		else
		    URL='http://www.webdetails.pt/ficheiros/cde/14.12.10.1/4.x/dist.zip'
		fi
	else
		if [ $BRANCH = 'dev' ]
		then
    		URL='http://ci.pentaho.com/job/pentaho-cde/lastSuccessfulBuild/artifact/cde-pentaho5/dist/*zip*/dist.zip'
		else
		    URL='http://www.webdetails.pt/ficheiros/cde/14.12.10.1/5.x/dist.zip'
		fi
	fi
	download_file "CDE"  "$URL"  "dist.zip"  ".tmp/cde"
	rm -f .tmp/dist/marketplace.xml
	unzip -o .tmp/cde/dist.zip -d .tmp > /dev/null
	chmod -R u+rwx .tmp
	echo "Done"
}

downloadCGG (){
	# CGG
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
		if [ $BRANCH = 'dev' ]
		then
		    URL='http://ci.pentaho.com/job/pentaho-cgg-pentaho/lastSuccessfulBuild/artifact/cgg-pentaho/dist/*zip*/dist.zip'
		else
	    	URL='http://www.webdetails.pt/ficheiros/cgg/14.12.10/4.x/dist.zip'
	    fi
	else
		if [ $BRANCH = 'dev' ]
		then
    		URL='http://ci.pentaho.com/job/pentaho-cgg/lastSuccessfulBuild/artifact/cgg-pentaho5/dist/*zip*/dist.zip'
    	else
    	    URL='http://www.webdetails.pt/ficheiros/cgg/14.12.10/5.x/dist.zip'
    	fi
	fi
	download_file "CGG" "$URL" "dist.zip" ".tmp/cgg"
	rm -f .tmp/dist/marketplace.xml
	unzip -o .tmp/cgg/dist.zip -d .tmp > /dev/null
	chmod -R u+rwx .tmp
	echo "Done"
}

downloadCFR (){
	# CFR
    if [[ "$BASERVER_VERSION" = "4x" ]]; then
	    URL='http://ci.pentaho.com/job/pentaho-cfr-pentaho/lastSuccessfulBuild/artifact/cfr-pentaho/dist/*zip*/dist.zip'
	else
	    URL='http://ci.pentaho.com/job/pentaho-cfr/lastSuccessfulBuild/artifact/cfr-pentaho5/dist/*zip*/dist.zip'
	fi
	download_file "CFR" "$URL" "dist.zip" ".tmp/cfr"
	rm -f .tmp/dist/marketplace.xml
	unzip -o .tmp/cfr/dist.zip -d .tmp > /dev/null
	chmod -R u+rwx .tmp
	echo "Done"
}

downloadSparkl (){
	# Sparkl
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
		URL='http://ci.pentaho.com/job/Sparkl-4.x/lastSuccessfulBuild/artifact/dist/*zip*/dist.zip'
	else
		URL='http://ci.pentaho.com/job/Sparkl/lastSuccessfulBuild/artifact/dist/*zip*/dist.zip'
	fi
	download_file "Sparkl" "$URL" "dist.zip" ".tmp/sparkl"
	rm -f .tmp/dist/marketplace.xml
	unzip -o .tmp/sparkl/dist.zip -d .tmp > /dev/null
	chmod -R u+rwx .tmp
	echo "Done"
}

downloadCDC (){
	# CDC
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
		if [ $BRANCH = 'dev' ]
		then
	        URL='http://ci.pentaho.com/job/pentaho-cdc/lastSuccessfulBuild/artifact/cdc-pentaho/dist/*zip*/dist.zip'
	    else
	    	URL='http://www.webdetails.pt/ficheiros/cdc/14.12.10/4.x/dist.zip'
	    fi
	else
		if [ $BRANCH = 'dev' ]
		then
	        URL='http://ci.pentaho.com/job/pentaho-cdc/lastSuccessfulBuild/artifact/cdc-pentaho5/dist/*zip*/dist.zip'
	    else
	    	URL='http://www.webdetails.pt/ficheiros/cdc/14.12.10/5.x/dist.zip'
	    fi
	fi

	download_file "CDC" "$URL" "dist.zip" ".tmp/cdc"
	rm -f .tmp/dist/marketplace.xml
	unzip -o .tmp/cdc/dist.zip -d .tmp > /dev/null
	chmod -R u+rwx .tmp
	echo "Done"
}


downloadCDV (){
	# CDV
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
		if [ $BRANCH = 'dev' ]
		then
	        URL='http://ci.pentaho.com/job/pentaho-cdv-pentaho/lastSuccessfulBuild/artifact/cdv-pentaho/dist/*zip*/dist.zip'
	    else
	    	URL='http://www.webdetails.pt/ficheiros/cdv/14.10.15/4.x/dist.zip'
	    fi
	else
		if [ $BRANCH = 'dev' ]
		then	
        	URL='http://ci.pentaho.com/job/pentaho-cdv/lastSuccessfulBuild/artifact/cdv-pentaho5/dist/*zip*/dist.zip'
        else
            echo "CDV [stable] not available for Pentaho 5.x."
        fi
	fi
	download_file "CDV" "$URL" "dist.zip" ".tmp/cdv"
	rm -f .tmp/dist/marketplace.xml
	unzip -o .tmp/cdv/dist.zip -d .tmp > /dev/null
	chmod -R u+rwx .tmp
	echo "Done"
}

downloadSaiku (){
	# SAIKU
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
		if [ $BRANCH = 'dev' ]
		then
			URL='http://ci.analytical-labs.com/job/saiku-bi-platform-plugin/lastSuccessfulBuild/artifact/saiku-bi-platform-plugin/target/*zip*/target.zip'
			download_file "SAIKU" "$URL" "target.zip" ".tmp/saiku"
			rm -f .tmp/dist/marketplace.xml
			unzip -o .tmp/saiku/target.zip -d .tmp > /dev/null
			chmod -R u+rwx .tmp
			mv .tmp/target/saiku-* .tmp
		else
			URL='http://meteorite.bi/downloads/saiku-plugin-2.5.zip'
			download_file "SAIKU" "$URL" "saiku-plugin.zip" ".tmp"
		fi
	else
		if [ $BRANCH = 'dev' ]
		then
            echo 'SAIKU [trunk] not available for download. downloading stable'
        fi	    
        URL='http://meteorite.bi/downloads/saiku-plugin-p5-3.0.6.zip'
		download_file "SAIKU" "$URL" "saiku-plugin.zip" ".tmp"
	fi
	echo "Done"
}


downloadSaikuAdhoc (){
	# SAIKU Adhoc
	if [ $BRANCH = 'dev' ]
	then
    	echo 'SAIKU ADHOC [trunk] not available for download. downloading stable'
		URL='https://github.com/Mgiepz/saiku-reporting/raw/gh-pages/downloads/saiku-adhoc-plugin-1.0-GA.zip'
		download_file "SAIKU_ADHOC" "$URL" "saiku-adhoc-plugin.zip" ".tmp"
	else
		URL='https://github.com/Mgiepz/saiku-reporting/raw/gh-pages/downloads/saiku-adhoc-plugin-1.0-GA.zip'
		download_file "SAIKU_ADHOC" "$URL" "saiku-adhoc-plugin-1.0-GA.zip" ".tmp"
    fi
	echo "Done"
}


# Define install functions

installSamples() {
	SAMPLES_LOCATION="$1"
	SAMPLES_ZIP_FULLNAME="$2"
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
		if [ ! -d  "$SOLUTION_DIR/plugin-samples" ]
		then
			mkdir "$SOLUTION_DIR/plugin-samples"
		fi
		if [ ! -f  "$SOLUTION_DIR/plugin-samples/index.xml" ]
		then
			echo '<index><visible>true</visible><name>Plugin Samples</name><description>Plugin Samples</description></index>' > "$SOLUTION_DIR/plugin-samples/index.xml"
		fi
		unzip -o -q "$SAMPLES_ZIP_FULLNAME" -d "$SOLUTION_DIR/$SAMPLES_LOCATION"
	else
		# Repackage samples with new Repository Path:
		SAMPLES_ZIP_BASENAME=`basename "$SAMPLES_ZIP_FULLNAME"`
		REBASE_TMP_DIR=`dirname $SAMPLES_ZIP_FULLNAME`"/zip_rebase"
		rm -rf "$REBASE_TMP_DIR"
		mkdir -p "$REBASE_TMP_DIR/public/$SAMPLES_LOCATION"
		unzip -o -q "$SAMPLES_ZIP_FULLNAME" -d "$REBASE_TMP_DIR/public/$SAMPLES_LOCATION"
		(cd "$REBASE_TMP_DIR" ; zip -qr "../${SAMPLES_ZIP_BASENAME}.rebased" * )
		mv "${SAMPLES_ZIP_FULLNAME}.rebased" "$SOLUTION_DIR/system/default-content/$SAMPLES_ZIP_BASENAME"
		rm -rf "$REBASE_TMP_DIR" "${SAMPLES_ZIP_FULLNAME}.rebased"
	fi
}

installMarketplace (){
	rm -rf $SOLUTION_DIR/system/marketplace
	unzip -o .tmp/marketplace/plugin.zip -d "$SOLUTION_DIR/system/" > /dev/null
}

installCDF (){
	rm -rf $SOLUTION_DIR/system/pentaho-cdf

	# Removing samples dir. First two are deprecated
	rm -rf $SOLUTION_DIR/bi-developers/cdf-samples
	rm -rf $SOLUTION_DIR/plugin-samples/cdf-samples
	rm -rf $SOLUTION_DIR/plugin-samples/pentaho-cdf

	unzip -o .tmp/dist/pentaho-cdf$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null
	installSamples plugin-samples .tmp/dist/pentaho-cdf-samples$FILESUFIX*zip
}

installCDE (){
	rm -rf $SOLUTION_DIR/system/pentaho-cdf-dd

	# Removing samples dir. First two are deprecated
	rm -rf $SOLUTION_DIR/cde_sample
	rm -rf $SOLUTION_DIR/plugin-samples/cde_sample
	rm -rf $SOLUTION_DIR/plugin-samples/pentaho-cdf-dd

	unzip -o .tmp/dist/pentaho-cdf-dd$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null
	installSamples plugin-samples .tmp/dist/pentaho-cdf-dd-solution$FILESUFIX.zip
}

installCDA (){
	rm -rf $SOLUTION_DIR/system/cda

	# Removing samples dir. First is deprecated
	rm -rf $SOLUTION_DIR/bi-developers/cda
	rm -rf $SOLUTION_DIR/plugin-samples/cda

    unzip -o .tmp/dist/cda$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null
	installSamples plugin-samples .tmp/dist/cda-samples$FILESUFIX.zip
}

installCGG (){
	rm -rf $SOLUTION_DIR/system/cgg

	unzip -o .tmp/dist/cgg$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null

	# Changes to the server; 1 - delete batik; 2 - copy new one plus xml and fop

	if [[ $HAS_WEBAPP_PATH -eq 1 ]]
	then
		LIB_DIR=$WEBAPP_PATH/WEB-INF/lib
		CGG_DIR=$SOLUTION_DIR/system/cgg/lib

		rm -rf $LIB_DIR/batik-* $LIB_DIR/xml-apis* $LIB_DIR/xmlgraphics*
		cp $CGG_DIR/batik-[^j]* $CGG_DIR/xml* $LIB_DIR

	else
		echo
		echo ' [CGG] No webapp path provided, if you are using pentaho older than 4.5 cgg will not work properly)'
	fi
}

installCFR (){
	rm -rf $SOLUTION_DIR/system/cfr
    if [[ "$BASERVER_VERSION" = "4x" ]]; then
	    unzip -o .tmp/dist/cfr-pentaho*$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null
	else
	    unzip -o .tmp/dist/cfr-pentaho5$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null
	fi
}

installSparkl (){
	rm -rf $SOLUTION_DIR/system/sparkl
	unzip -o .tmp/dist/sparkl$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null
}

installCDC (){
	rm -rf $SOLUTION_DIR/system/cdc
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
        unzip -o .tmp/dist/cdc-pentaho$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null
	else	
		if [ $BRANCH = 'dev' ]
		then	
	        unzip -o .tmp/dist/cdc-pentaho5$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null
	    else
            unzip -o .tmp/dist/cdc$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null	    
	    fi

	fi


	# Changes to the server;

	# 1 - copy hazelcast to WEB-INF/lib
	LIB_DIR=$WEBAPP_PATH/WEB-INF/lib
	CDC_HAZELCAST_DIR=$SOLUTION_DIR/system/cdc/pentaho-lib
	rm -rf $LIB_DIR/hazelcast-*.jar
	rm -rf $LIB_DIR/cdc-hazelcast-*.jar
	cp $CDC_HAZELCAST_DIR/*.jar  $LIB_DIR
}


installCDV (){
	rm -rf $SOLUTION_DIR/system/cdv
	rm -rf $SOLUTION_DIR/plugin-samples/cdv
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
        unzip -o .tmp/dist/cdv-pentaho$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null
	else
        unzip -o .tmp/dist/cdv$FILESUFIX.zip -d "$SOLUTION_DIR/system/" > /dev/null
	fi
#	installSamples plugin-samples .tmp/dist/cdv-samples$FILESUFIX*zip
}

installSaiku (){
	rm -rf $SOLUTION_DIR/system/saiku
	unzip -o .tmp/saiku-plugin*zip -d "$SOLUTION_DIR/system/" > /dev/null
}

installSaikuAdhoc (){
	rm -rf $SOLUTION_DIR/system/saiku-adhoc
	unzip -o .tmp/saiku-adhoc-plugin*zip -d "$SOLUTION_DIR/system/" > /dev/null
}



# read options for stuff to download/install

INSTALL_MARKETPLACE=0
INSTALL_CDF=0
INSTALL_CDA=0
INSTALL_CDE=0
INSTALL_CGG=0
INSTALL_CFR=0
INSTALL_SPARKL=0
INSTALL_CDC=0
INSTALL_CDV=0
INSTALL_SAIKU=0
INSTALL_SAIKU_ADHOC=0

if  [ "$BRANCH" = "dev" ]; then
	if  [ "$MODULES" != "" ] || $ASSUME_YES; then
		INSTALL_MARKETPLACE=1
	else
		echo
		echo $ECHO_FLAG "Install Marketplace? This will delete everything in $SOLUTION_DIR/system/marketplace. you sure? (y/N) "
		read -e answer < /dev/tty

		case $answer in
		  [Yy]* ) INSTALL_MARKETPLACE=1;;
		  * ) ;;
		esac
	fi
fi


if  [ "$MODULES" != "" ] || $ASSUME_YES; then
	INSTALL_CDF=1
else
	echo
	echo $ECHO_FLAG "Install CDF? This will delete everything in $SOLUTION_DIR/system/pentaho-cdf. you sure? (y/N) "
	read -e answer < /dev/tty

	case $answer in
	  [Yy]* ) INSTALL_CDF=1;;
	  * ) ;;
	esac
fi

if [ "$MODULES" != "" ] ||  $ASSUME_YES; then
	INSTALL_CDA=1
else
	echo
	echo $ECHO_FLAG "Install CDA? This will delete everything in $SOLUTION_DIR/system/cda. you sure? (y/N) "
	read -e answer < /dev/tty

	case $answer in
	  [Yy]* ) INSTALL_CDA=1;;
	  * ) ;;
	esac
fi

if [ "$MODULES" != "" ] ||  $ASSUME_YES; then
	INSTALL_CDE=1
else
	echo
	echo $ECHO_FLAG "Install CDE? This will delete everything in $SOLUTION_DIR/system/pentaho-cdf-dd. you sure? (y/N) "
	read -e answer < /dev/tty

	case $answer in
	  [Yy]* ) INSTALL_CDE=1;;
	  * ) ;;
	esac
fi


if [ "$MODULES" != "" ] || $ASSUME_YES; then
    INSTALL_CGG=1
else
    echo
	echo $ECHO_FLAG "Install CGG? This will delete everything in $SOLUTION_DIR/system/cgg. you sure? (y/N) "
	read -e answer < /dev/tty
	case $answer in
	    [Yy]* ) INSTALL_CGG=1;;
		* ) ;;
	esac
fi


if  [ "$BRANCH" = "dev" ]; then
	if  [ "$MODULES" != "" ] || $ASSUME_YES; then
		INSTALL_CFR=1
	else
		echo
		echo $ECHO_FLAG "Install CFR? This will delete everything in $SOLUTION_DIR/system/cfr you sure? (y/N) "
		read -e answer < /dev/tty

		case $answer in
		  [Yy]* ) INSTALL_CFR=1;;
		  * ) ;;
		esac
	fi
fi


if  [ "$BRANCH" = "dev" ]; then
	if  [ "$MODULES" != "" ] || $ASSUME_YES; then
		INSTALL_Sparkl=1
	else
		echo
		echo $ECHO_FLAG "Install Sparkl? This will delete everything in $SOLUTION_DIR/system/sparkl you sure? (y/N) "
		read -e answer < /dev/tty

		case $answer in
		  [Yy]* ) INSTALL_SPARKL=1;;
		  * ) ;;
		esac
	fi
fi


if [[ $HAS_WEBAPP_PATH -eq 1 ]]
then
	if [ "$MODULES" != "" ] ||  $ASSUME_YES; then
        INSTALL_CDC=1
    else
		echo
		echo $ECHO_FLAG "Install CDC? This will delete everything in $SOLUTION_DIR/system/cdc. you sure? (y/N) "
		read -e answer < /dev/tty
        case $answer in
			[Yy]* ) INSTALL_CDC=1;;
		    * ) ;;
	    esac
    fi
else
	echo
    echo 'No webapp path provided, will not install CDC'
fi


if ([ $BRANCH = 'dev' ]  && [ $BASERVER_VERSION = '5x' ] ) || [ $BASERVER_VERSION = '4x' ];  then
    if [ "$MODULES" != "" ] ||  $ASSUME_YES; then
        INSTALL_CDV=1
    else
        echo
    	echo $ECHO_FLAG "Install CDV? This will delete everything in $SOLUTION_DIR/system/cdv. you sure? (y/N) "
	    read -e answer < /dev/tty

    	case $answer in
	        [Yy]* ) INSTALL_CDV=1;;
		    * ) ;;
        esac
    fi
fi



if  [ $BASERVER_VERSION = '5x' ]; then
    if [ "$MODULES" != "" ] ||  $ASSUME_YES; then
	    INSTALL_SAIKU=1
    else
	    echo
    	echo $ECHO_FLAG "Install Saiku? This will delete everything in $SOLUTION_DIR/system/saiku. you sure? (y/N) "
	    read -e answer < /dev/tty

    	case $answer in
	      [Yy]* ) INSTALL_SAIKU=1;;
    	  * ) ;;
	    esac
    fi
fi

if [ $BASERVER_VERSION = '5x' ] || [ "$MODULES" != "" ] ||  $ASSUME_YES; then
    INSTALL_SAIKU_ADHOC=1
else
    echo
	echo $ECHO_FLAG "Install Saiku Adhoc? This will delete everything in $SOLUTION_DIR/system/saiku-adhoc. you sure? (y/N) "
	read -e answer < /dev/tty

	case $answer in
	    [Yy]* ) INSTALL_SAIKU_ADHOC=1;;
        * ) ;;
    esac
fi



nothingToDo (){
	echo Nothing to do. Exiting
	cleanup
	exit 1
}

if [ "$MODULES" != "" ]; then
  INSTALL_MARKETPLACE=0
  INSTALL_CDF=0
  INSTALL_CDA=0
  INSTALL_CDE=0
  INSTALL_CGG=0
  INSTALL_CFR=0
  INSTALL_SPARKL=0
  INSTALL_CDC=0
  INSTALL_CDV=0
  INSTALL_SAIKU=0
  INSTALL_SAIKU_ADHOC=0
  MODULES_ARR=$(echo $MODULES | tr "," "\n")
  for MODULE in $MODULES_ARR
  do
    case $MODULE in
	  marketplace) INSTALL_MARKETPLACE=1;;
	  cdf) INSTALL_CDF=1;;
      cda) INSTALL_CDA=1;;
      cde) INSTALL_CDE=1;;
      cgg) INSTALL_CGG=1;;
      cfr) INSTALL_CFR=1;;
      sparkl) INSTALL_SPARKL=1;;
      cdc) INSTALL_CDC=1;;
      cdv) INSTALL_CDV=1;;
      saiku) INSTALL_SAIKU=1;;
      saikuadhoc) INSTALL_SAIKU_ADHOC=1;;
        * ) ;;
    esac
  done
fi


[ $INSTALL_MARKETPLACE -ne 0 ] || [ $INSTALL_CDF -ne 0 ] || [ $INSTALL_CDE -ne 0 ] || [ $INSTALL_CDA -ne 0 ] || [ $INSTALL_CGG -ne 0 ] || [ $INSTALL_CFR -ne 0 ] || [ $INSTALL_SPARKL -ne 0 ] || [ $INSTALL_CDC -ne 0 ] || [ $INSTALL_CDV -ne 0 ]  || [ $INSTALL_SAIKU -ne 0 ] || [ $INSTALL_SAIKU_ADHOC -ne 0 ] ||  nothingToDo


# downloading files

echo
echo Downloading files
echo


[ $INSTALL_MARKETPLACE -eq 0 ] || downloadMarketplace
[ $INSTALL_CDF -eq 0 ] || downloadCDF
[ $INSTALL_CDA -eq 0 ] || downloadCDA
[ $INSTALL_CDE -eq 0 ] || downloadCDE
[ $INSTALL_CGG -eq 0 ] || downloadCGG
[ $BRANCH != 'dev' ] || [ $INSTALL_CFR -eq 0 ] || downloadCFR
[ $INSTALL_SPARKL -eq 0 ] || downloadSparkl
[ $INSTALL_CDC -eq 0 ] || downloadCDC
([ $BRANCH != 'dev' ]  && [ $BASERVER_VERSION = '5x' ] ) || [ $INSTALL_CDV -eq 0 ] || downloadCDV
[ $BASERVER_VERSION = '4x' ] || [ $INSTALL_SAIKU -eq 0 ] || downloadSaiku
[ $BASERVER_VERSION = '5x' ] || [ $INSTALL_SAIKU_ADHOC -eq 0 ] || downloadSaikuAdhoc


# installing files

echo
echo Installing files
echo

[ $INSTALL_MARKETPLACE -eq 0 ] || installMarketplace
[ $INSTALL_CDF -eq 0 ] || installCDF
[ $INSTALL_CDA -eq 0 ] || installCDA
[ $INSTALL_CDE -eq 0 ] || installCDE
[ $INSTALL_CGG -eq 0 ] || installCGG
[ $BRANCH != 'dev' ] || [ $INSTALL_CFR -eq 0 ] || installCFR
[ $INSTALL_SPARKL -eq 0 ] || installSparkl
[ $INSTALL_CDC -eq 0 ] || installCDC
([ $BRANCH != 'dev' ]  && [ $BASERVER_VERSION = '5x' ] ) || [ $INSTALL_CDV -eq 0 ] || installCDV
[ $BASERVER_VERSION = '4x' ] || [ $INSTALL_SAIKU -eq 0 ] || installSaiku
[ $BASERVER_VERSION = '5x' ] || [ $INSTALL_SAIKU_ADHOC -eq 0 ] || installSaikuAdhoc



cleanup

echo
echo Done!
echo

exit 0
