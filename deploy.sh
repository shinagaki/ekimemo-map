#!/bin/sh

BASEDIR=$(cd $(dirname $0)/; pwd)
cd $BASEDIR

gsutil -m -h "Cache-Control:public, max-age=10" cp -r static/* gs://ekimemo-map2
