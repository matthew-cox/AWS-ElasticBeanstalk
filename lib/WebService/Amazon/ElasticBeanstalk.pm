package WebService::Amazon::ElasticBeanstalk;
use base qw( WebService::Simple );

use 5.006;
use strict;
use warnings FATAL => 'all';

#binmode STDOUT, ":encoding(UTF-8)";

use AWS::Signature4;
use Carp;
use HTTP::Request::Common;
use LWP;
use Params::Validate qw( :all );
use Readonly;
use Smart::Comments;
#use Smart::Comments '###', '####';
#use Smart::Comments '###', '####', '#####';
require XML::Simple;

=encoding utf-8

=head1 NAME

WebService::Amazon::ElasticBeanstalk - Basic interface to Amazon ElasticBeanstalk

=head1 VERSION

Version 0.0.1

=cut

use version;
our $VERSION = version->declare("v0.0.1");

=head1 SYNOPSIS

This module provides a Perl wrapper around Amazon's 
( L<http://aws.amazon.com> ) ElasticBeanstalk API.  You will need 
to be a Smartling customer and have your API Key and project Id
before you'll be able to do anything with this module.

B<Note:> Some parameter validation is purposely lax. The API will 
generally fail when invalid params are passed. The errors are not 
helpful.

=cut


# From: http://docs.aws.amazon.com/general/latest/gr/rande.html#elasticbeanstalk_region
Readonly our %REGIONS => ( 'us-east-1'      => 'https://elasticbeanstalk.us-east-1.amazonaws.com',
                           'us-west-1'      => 'https://elasticbeanstalk.us-west-1.amazonaws.com',
                           'us-west-2'      => 'https://elasticbeanstalk.us-west-2.amazonaws.com',
                           'eu-west-1'      => 'https://elasticbeanstalk.eu-west-1.amazonaws.com',
                           'eu-central-1'   => 'https://elasticbeanstalk.eu-central-1.amazonaws.com',
                           'ap-southeast-1' => 'https://elasticbeanstalk.ap-southeast-1.amazonaws.com',
                           'ap-southeast-2' => 'https://elasticbeanstalk.ap-southeast-2.amazonaws.com',
                           'ap-northeast-1' => 'https://elasticbeanstalk.ap-northeast-1.amazonaws.com',
                           'sa-east-1'      => 'https://elasticbeanstalk.sa-east-1.amazonaws.com'
                           );

# Global API Version
Readonly our $API_VERSION => '2010-12-01';

# some defaults
__PACKAGE__->config(
  base_url => $REGIONS{'us-east-1'},
);

# Global patterns for param validation
Readonly our $REGEX_ID     => '^[A-Z0-9]{20}$';
Readonly our $REGEX_REGION => '^[a-z]{2}-[a-z].*?-\d$';
Readonly our $REGEX_SECRET => '^[A-Za-z0-9/+]{40}$';

Readonly our $REGEX_CONDITIONS => '^(haveAtLeastOneUnapproved|haveAtLeastOneApproved|haveAtLeastOneTranslated|haveAllTranslated|haveAllApproved|haveAllUnapproved)$';
Readonly our $REGEX_FILETYPES  => '^(android|docx|ios|gettext|html|xlsx|javaProperties|json|pptx|xliff|xlsx|xml|yaml)$';
Readonly our $REGEX_FILEURI    => '^\S+$';
Readonly our $REGEX_INT        => '^\d+$';
Readonly our $REGEX_RETYPE     => '^(pending|published|pseudo)$';
Readonly our $REGEX_URL        => '^(https?|ftp|file)://.+$';
# From: http://www.pelagodesign.com/blog/2009/05/20/iso-8601-date-validation-that-doesnt-suck/
Readonly our $REGEX_DATE_ISO8601 => '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$';

=head1 INTERFACE

=head2 new

Inherited from L<WebService::Simple>, and takes all the same arguments. 
You B<must> provide the Amazon required arguments of B<id>, B<region>, and 
B<secret> in the param hash:

 my $ebn = WebService::Amazon::ElasticBeanstalk->new( param => { id     => $AWS_ACCESS_KEY_ID,
                                                                 region => 'us-east-1',
                                                                 secret => $AWS_ACCESS_KEY_SECRET } );

=over 4

=item B<Parameters>

=item id B<(required)>

You can find within your Smartling project's dashboard: 
L<https://dashboard.smartling.com/settings/api>

=item region I<(optional)> - defaults to us-east-1

You can find vailable regions at: 
L<http://docs.aws.amazon.com/general/latest/gr/rande.html#elasticbeanstalk_region>

=item secret B<(required)>

You can find within your Smartling project's dashboard: 
L<https://dashboard.smartling.com/settings/api>

=back

=cut

my( %ALL_SPECS ) = (
  id     => { type => SCALAR, regex => qr/$REGEX_ID/, },
  region => { type => SCALAR, regex => qr/$REGEX_REGION/, },
  secret => { type => SCALAR, regex => qr/$REGEX_SECRET/, },
);
#   apiKey             => { type => SCALAR, regex => qr/$REGEX_APIKEY/, },
#   approved           => { type => SCALAR, },
#   callbackUrl        => { type => SCALAR, regex => qr/$REGEX_URL/, },
#   conditions         => { type => ARRAYREF },
#   file               => { type      => SCALAR,
#                           callbacks => {
#                             'readable file' => sub { my( $f ) = shift(); return "$f" ne "" && -r "$f" },
#                             'less than 5MB' => sub { my( $f ) = shift(); return "$f" ne "" && -r "$f" && (sprintf( "%.2f", (-s "$f") / 1024 / 1024) < 5 ); };
#                             },
#                           untaint => 1
#                         },
#   fileType           => { type => SCALAR, regex => qr/$REGEX_FILETYPES/, },
#   fileTypes          => { type => ARRAYREF, regex => qr/$REGEX_FILETYPES/, },
#   fileUri            => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
#   lastUploadedAfter  => { type => SCALAR, regex => qr/$REGEX_DATE_ISO8601/, },
#   lastUploadedBefore => { type => SCALAR, regex => qr/$REGEX_DATE_ISO8601/, },
#   limit              => { type => SCALAR, regex => qr/$REGEX_INT/, },
#   locale             => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
#   newFileUri         => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
#   offset             => { type => SCALAR, regex => qr/$REGEX_INT/, },
#   projectId          => { type => SCALAR, regex => qr/$REGEX_PROJID/, },
#   retrievalType      => { type => SCALAR, regex => qr/$REGEX_RETYPE/, },
#   uriMask            => { type => SCALAR, },
# );

my( %global_spec ) = ( 
  id     => $ALL_SPECS{id},
  region => $ALL_SPECS{region},
  secret => $ALL_SPECS{secret},
);

# Override valida options, set API version and create XML parser
sub new {
  my( $class, %args ) = @_;
  my $self = $class->SUPER::new(%args);
  
  # set our API version
  $self->{api_version} = $API_VERSION;
  
  # this is silly, but easier for validation
  my( @temp_params ) = %{ $self->{basic_params} };
  my %params = validate( @temp_params, \%global_spec );
  
  # change the endpoint for the requested region
  if ( $params{region} and "$params{region}" ne "us-east-1" ) {
    carp( "Region specified. Switching to correct region endpoint..." );
    $self->{base_url} = $REGIONS{$params{region}};
  }
  
  # for parsing the responses
  $self->{xs} = XML::Simple->new();
  
  return bless($self, $class);
}

# override parent get to perform the required AWS signatures
sub get {
  my( $self, %args ) = @_;
  #my $self = $class->SUPER::new(%args);
  
  ##### $self
  my $signer = AWS::Signature4->new( -access_key => $self->{basic_params}{id},
                                     -secret_key => $self->{basic_params}{secret} );
                                    
  my $ua = LWP::UserAgent->new();

  ### %args
  if ( !exists( $args{params} ) ) {
    carp( "No paramerter provided for request!" );
    return undef;
  }
  else {
    $args{params}{Version} = $self->{api_version};
  }

  my $uri = URI->new( $self->{base_url} );
  $uri->query_form( $args{params} );
  #### $uri

  my $url = $signer->signed_url($uri); # This gives a signed URL that can be fetched by a browser
  ### $url
  # This doesn't quite work (it wants path and args onyl)
  #my $response = $self->SUPER::get( $url ); 
  my $response = $ua->get($url);
  ### $response
  if ($response->is_success) {
     return $self->{xs}->XMLin( $response->decoded_content );
  }
  else {
    carp( $response->status_line );
    return undef;
  }
  #return bless($self, $class);
}

# override parent post to perform the required AWS signatures
sub post {
  my( $class, %args ) = @_;
  my $self = $class->SUPER::new(%args);
  
  my $signer = AWS::Signature4->new(-access_key => $self->{basic_params}{id},
                                    -secret_key => $self->{basic_params}{secret});
                                    
  my $ua     = LWP::UserAgent->new();

  # Example POST request
  my $request = POST('https://iam.amazonaws.com',
                     [Action=>'ListUsers',
                      Version=>'2010-05-08']);
  $signer->sign($request);
  my $response = $ua->request($request);
  
  return bless($self, $class);
}


# CheckDNSAvailability
# CreateApplication
# CreateApplicationVersion
# CreateConfigurationTemplate
# CreateEnvironment
# CreateStorageLocation
# DeleteApplication
# DeleteApplicationVersion
# DeleteConfigurationTemplate
# DeleteEnvironmentConfiguration
# DescribeApplicationVersions
# DescribeApplications
# DescribeConfigurationOptions
# DescribeConfigurationSettings
# DescribeEnvironmentResources
# DescribeEnvironments
# DescribeEvents
## ListAvailableSolutionStacks
# RebuildEnvironment
# RequestEnvironmentInfo
# RestartAppServer
# RetrieveEnvironmentInfo
# SwapEnvironmentCNAMEs
# TerminateEnvironment
# UpdateApplication
# UpdateApplicationVersion
# UpdateConfigurationTemplate
# UpdateEnvironment
# ValidateConfigurationSettings

=head2 fileDelete(I<%params>)

Removes the file from Smartling. The file will no longer be available 
for download. Any complete translations for the file remain available 
for use within the system.

Smartling deletes files asynchronously and it typically takes a few 
minutes to complete. While deleting a file, you can not upload a file 
with the same fileUri.

Refer to 
L<https://docs.smartling.com/display/docs/Files+API#FilesAPI-/file/delete%28DELETE%29>

=cut

my( %file_delete_spec ) = ( fileUri => $ALL_SPECS{fileUri} );

=over 4

=item B<Parameters>

=item fileUri B<(required)>

Value that uniquely identifies the file.

=item B<Returns: JSON result from API>

=over 4

 {"response":{"code":"SUCCESS","messages":[],"data":null,}}

=back

=back

=cut

# sub fileDelete {
#   my $self = shift();
#
#   # validate
#   my %params = validate( @_, \%file_delete_spec );
#
#   # This code is essentially a simplified duplication of WebService::Simple->get
#   # with the HTTP method changed to delete
#   my $uri = $self->request_url(
#       url        => $self->base_url,
#       extra_path => "file/delete",
#       params     => { %{ $self->basic_params }, %params }
#   );
#
#   warn "Request URL is $uri$/" if $self->{debug};
#
#   my @headers = @_;
#
#   my $response = $self->SUPER::delete( $uri, @headers );
#   if ( !$response->is_success ) {
#       Carp::croak("request to $uri failed");
#   }
#
#   $response = WebService::Simple::Response->new_from_response(
#       response => $response,
#       parser   => $self->response_parser
#   );
#
#   return $response->parse_response;
# }

=head2 ListAvailableSolutionStacks( )

Returns a list of the available solution stack names.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_ListAvailableSolutionStacks.html>

=over 4

=item B<Parameters>

B<none>

=item B<Returns: JSON result from API>

=over 4

 {
   "locales": [
       {
           "name": "Spanish",
           "locale": "es",
           "translated": "Español"
       },
       {
           "name": "French",
           "locale": "fr-FR",
           "translated": "Français"
       }
   ]
 }

 locale - Locale identifier

 name - Source locale name

 translated - Localized locale name

=back

=back

=cut

sub ListAvailableSolutionStacks {
  my $self = shift;
  return $self->get( params => { Operation => 'ListAvailableSolutionStacks' } );
}

=head1 AUTHOR

Matthew Cox, C<< <mcox at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-smartling at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Smartling>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Smartling


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Smartling>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Smartling>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Smartling>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Smartling/>

=back

=head1 SEE ALSO

perl(1), L<WebService::Simple>, L<JSON>, L<HTTP::Common::Response>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Matthew Cox.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WebService::Amazon::ElasticBeanstalk
__END__
