#!/usr/bin/env perl
use lib './lib';
use Smart::Comments;
use WebService::Amazon::ElasticBeanstalk;

my( %PARAMS ) = ( id     => 'FOO',
                  region => 'us-east-1',
                  secret => 'bar' );

my( $ebn ) = WebService::Amazon::ElasticBeanstalk->new( param => \%PARAMS );
my( $rez ) = $ebn->ListAvailableSolutionStacks();
### $rez