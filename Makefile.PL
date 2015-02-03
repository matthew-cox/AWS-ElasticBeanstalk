use inc::Module::Install;
 
# Define metadata
name     'WebService-Amazon-ElasticBeanstalk';
all_from 'lib/WebService/Amazon/ElasticBeanstalk.pm';

# Specific dependencies
requires 'AWS::Signature4';
requires 'Carp';
requires 'Params::Validate';
requires 'Readonly';
requires 'version';
requires 'WebService::Simple';
requires 'Xml::Simple';

WriteAll( meta => 1 );