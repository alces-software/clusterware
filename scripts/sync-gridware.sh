#!/bin/bash
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "$0: must set AWS_ACCESS_KEY_ID"
    exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "$0: must set AWS_SECRET_ACCESS_KEY"
    exit 1
fi

if [ "$1" == "--dry-run" ]; then
    dry_run="--dry-run"
fi

#regions="eu-west-1 eu-central-1 ap-northeast-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 sa-east-1 us-east-1 us-west-1 us-west-2 ca-central-1 eu-west-2"
regions="eu-west-1 eu-central-1 ap-southeast-2 us-east-1"

cd $(dirname "$0")
for r in $regions; do
    echo ""
    echo "== Syncing: ${r} =="
    s3cmd sync ${dry_run} --exclude '$dist/*' --exclude '$test/*' --exclude '$data/*' --delete-removed -F -P s3://packages.alces-software.com/gridware/ s3://alces-gridware-${r}/upstream/
    s3cmd sync ${dry_run} --delete-removed -F -P 's3://packages.alces-software.com/gridware/$dist/' s3://alces-gridware-${r}/dist/
    s3cmd sync ${dry_run} --delete-removed -F -P 's3://packages.alces-software.com/gridware/$data/' s3://alces-gridware-${r}/data/
    echo "==================="
done
