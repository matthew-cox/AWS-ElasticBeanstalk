#!/bin/bash -x
rm -f MYMETA.* META.*
perl Makefile.PL
cp MYMETA.json META.json
cp MYMETA.yml META.yml
rm -f README; perldoc -t ./lib/WebService/Amazon/ElasticBeanstalk.pm > README
rm -f README.md; pod2markdown ./lib/WebService/Amazon/ElasticBeanstalk.pm > README.md
