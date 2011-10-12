#!/bin/bash -ex
# $AWS_SECRET_ACCESS_KEY -- Amazon WS credential: secret access key
# $AWS_ACCESS_KEY_ID     -- Amazon WS credential: access key

### Do nothing on reboot
if test "$RS_REBOOT" = "true" ; then
  echo "Skipping installation..."
  exit 0
fi
## required parameters
version=$RELEASE_VERSION
app_name=common
#app_s3_bucket=htc-cs-aps-sb
app_name=common
web_root_dir=/var/www
mkdir -p $web_root_dir
app_root_dir=/var/webapps/
mkdir -p $app_root_dir
relase_name=htc-common-lib-$version
app_pkg_name="$relase_name-distribution.zip"

## Install the latest s3sync gem
gem install s3sync --no-ri --no-rdoc

## Enable EU Support
export AWS_CALLING_FORMAT=SUBDOMAIN

## Prepare a temporary directory
temp_dir="/tmp/s3_temp"
mkdir -p $temp_dir

## Retrieve the code from S3 and unpack it
echo "Downloading $app_pkg_file from S3:$APPLICATION_CODE_BUCKET..."
s3cmd get $APPLICATION_CODE_BUCKET:$app_pkg_name $temp_dir/$app_pkg_name

# Check if anything was downloaded - the directory is not empty.
[ "$(du -s $temp_dir| cut -f1)" -gt "8" ] || exit -1

### Installs the hub promotion app
if [ -e "$temp_dir/$app_pkg_name" ]; then
  logger -t $app_name "start to deploy package file $temp_dir/$app_pkg_file"
  #extact package file to app folder.
  unzip $temp_dir/$app_pkg_name -d $app_root_dir
  logger -t $app_name "activate package $relase_name"
  #setting current app.
  if [ -e $web_root_dir/$app_name ]; then
    mv  $web_root_dir/$app_name{,.rollback}
  fi
  ln -s $app_root_dir/$relase_name $web_root_dir/$app_name
fi

exit 0
