#!/bin/bash

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
