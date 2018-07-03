#!/bin/sh

# Set default variables 
TOMCAT_PATH=/var/lib/tomcat7/webapps/ROOT
DRY_RUN=
BUNDLE_PATH=
LETSENCRYPT_PATH=
DOMAIN=

while getopts b:t:d:l:r option
do
case "${option}"
in
b) BUNDLE_PATH=${OPTARG};;
t) TOMCAT_PATH=${OPTARG};;
d) DOMAIN=${OPTARG};;
l) LETSENCRYPT_PATH=$OPTARG;;
r) DRY_RUN=--dry-run
esac
done

# Domain parameter is mandatory
if [ -z $DOMAIN ] 
then
    echo "Domain parameter (-d www.example.com) is mandatory"
    exit
fi

# If letsencrypt path is not passed by parameter, set the default path
if [ -z $LETSENCRYPT_PATH ] ; then
    LETSENCRYPT_PATH=/etc/letsencrypt/live/$DOMAIN
fi

# If the bundle path is not passed by parameter, set the default path
if [ -z $BUNDLE_PATH ] ; then
    BUNDLE_PATH=$LETSENCRYPT_PATH
fi

# Log where each file is being saved to
echo "Saving bundle file to: $BUNDLE_PATH"
echo "Tomcat path set to: $TOMCAT_PATH"
echo "Renewing domain: $DOMAIN"
echo "Letsencrypt path set to: $LETSENCRYPT_PATH"

# This is the message that will match a successful result
SUCCESS_MESSAGE="Congratulations! Your certificate and chain have been saved at"

# Generate or renew the certificate 
OUTPUT="$(certbot-auto certonly -n --webroot -w $TOMCAT_PATH -d $DOMAIN $DRY_RUN)"

if echo "$OUTPUT" | grep -q "$SUCCESS_MESSAGE"
then
    echo "Bundling certificate and chain"
    openssl pkcs12 -export -out $BUNDLE_PATH/bundle.pfx -inkey $LETSENCRYPT_PATH/privkey.pem -in $LETSENCRYPT_PATH/cert.pem -certfile $LETSENCRYPT_PATH/chain.pem -password pass:changeit
    
    echo "Setting file permissions"
    chown tomcat7:tomcat7 $BUNDLE_PATH/bundle.pfx
    
    echo "Restarting Tomcat Server"
    service tomcat7 restart
else
    echo $OUTPUT;
fi
