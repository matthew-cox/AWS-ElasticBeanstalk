#!/usr/bin/env perl
use lib './lib';
use Smart::Comments;
use WebService::Amazon::ElasticBeanstalk;
            
my( %PARAMS ) = ( id     => 'foo',
                  region => 'us-east-1',
                  secret => 'bar' );

my( $rez );                  
my( $ebn ) = WebService::Amazon::ElasticBeanstalk->new( param => \%PARAMS );

( $rez ) = $ebn->CheckDNSAvailability( CNAMEPrefix => "fuckity-fuck-fuck" );
### $rez
#( $rez ) = $ebn->DescribeApplications( ApplicationNames => [ 'fuck' ] );
## $rez
( $rez ) = $ebn->DescribeApplicationVersions( ApplicationName => 'fuck', VersionLabels => [ 'fuck-0.0.3', 'fuck-0.0.4' ] );
### $rez
#( $rez ) = $ebn->ListAvailableSolutionStacks();
## $rez
#( $rez ) = $ebn->DescribeConfigurationOptions( ApplicationName => 'fuck' );
## $rez
#( $rez ) = $ebn->DescribeConfigurationSettings( ApplicationName => 'fuck', EnvironmentName => 'fuck-env' );
## $rez