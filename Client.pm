# Copyright (c) 1997-2001, Perforce Software, Inc.  All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL PERFORCE SOFTWARE, INC. BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
package P4::Client;
use strict;

require Exporter;
require DynaLoader;
use AutoLoader;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD );

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw( );
@EXPORT = qw( );

$VERSION = '1.1084';

bootstrap P4::Client $VERSION;

# Makes the Perforce commands usable as methods on the object for
# cleaner syntax. If it's not a valid method, you'll find out when
# Perforce recommends you read the help.
sub AUTOLOAD
{
	my $self = shift;
	my $ui = shift;
	my $cmd;
	($cmd = $AUTOLOAD ) =~ s/.*:://;
	$cmd = lc $cmd;
	return $self->Run( $ui, $cmd, @_ );
}

1;
__END__

=head1 NAME

P4::Client - Perl extension for the Perforce API

=head1 SYNOPSIS

  use P4::Client;
  use P4::UI;

  my $client = new P4::Client;
  my $ui = new P4::UI;

  $client->SetClient( $clientname );
  $client->SetPort ( $p4port );
  $client->SetPassword( $p4password );
  $client->Init() or die( "Failed to connect to Perforce Server" );
  $client->Run( $ui, "info" );
  $client->Run( $ui, "edit", "file.txt" );

  # OR, using Autoloaded methods instead of Client::Run().
  $client->Users( $ui );
  $client->Resolve( $ui, "-ay" );
  $client->Submit( $ui );

  $client->Final();


=head1 DESCRIPTION

This module provides a Perl interface to the Perforce API allowing you
to write Perl scripts which communicate directly with a Perforce server.

P4::Client is the main interface through which all commands are 
issued. The Perforce API is callback based though, and all interaction
with the user interface takes place through callbacks to methods of the
P4::UI object passed to the Run() method.

To customise the behaviour of the Perforce client, you should derive
your own class from P4::UI and override the relevant methods therein.

=head1 METHODS

The following paragraphs define the methods of a P4::Client
object. Note that due to the magic of the Autoloader, the
Perforce commands ( submit, client, filelog etc. ) are also
available as methods ( case insensitive ) as well as through
the Run() method.

=over 4

=item C<Client::new()>

Construct a new Client object. 

=item C<Client::Dropped()>

Returns true if the TCP/IP connection between client and server has 
been dropped.

=item C<Client::Final()>

Terminate the connection and clean up. Should be called before exiting
to cleanly disconnect.

=item C<Client::GetClient()>

Returns the current Perforce client name. This may have previously
been set by SetClient(), or may be taken from the environment or
P4CONFIG file if any. If all that fails, it will be your hostname.

=item C<Client::GetCwd()>

Returns the current working directory as your Perforce client sees
it.

=item C<Client::GetHost()>

Returns the client hostname. Defaults to your hostname, but can
be overridden with SetHost()

=item C<Client::GetPassword()>

Returns your Perforce password - in plain text if that's how it's
stored and currently on all except Windows platforms, that's the 
way it's done.  Taken from a previous call to SetPassword() or 
extracted from the environment ( $ENV{P4PASSWD} ), or a P4CONFIG 
file.

Note that the password is not transmitted in clear text. 

=item C<Client::GetPort()>

Returns the current address for your Perforce server. Taken from 
a previous call to SetPort(), or from $ENV{P4PORT} or a P4CONFIG
file.

=item C<Client::Init()>

Initializes the Perforce client and connects to the server.
Returns false on failure and true on success.

=item C<Client::Run( $ui, $cmd, [$arg...] )>

Run a Perforce command. The first argument must be a reference to a 
P4::UI object or a reference to an object derived from P4::UI. The
methods of that object will be used to interact with the user. The
subsequent arguments are the command you wish to run, and the 
arguments you want to pass to it. At this time, only strings and
numbers are valid argument types although through the magic of Perl
you can pass arrays or hashes but not references.

=item C<Client::SetClient( $client )>

Sets the name of your Perforce client. If you don't call this 
method, then the clientname will default according to the normal
Perforce conventions. i.e.

=over 4

=item 1. Value from file specified by P4CONFIG

=item 2. Value from C<$ENV{P4CLIENT}>

=item 3. Hostname

=back

=item C<Client::SetCwd( $path )>

Sets the current working directory for the client. This should
be called after the Init() and before the Run().

=item C<Client::SetPassword( $password )>

Set the password for the Perforce user, overriding all defaults.

=item C<Client::SetPort( [$host:]$port )>

Set the port on which your Perforce server is listening. Defaults
to:

=over 4

=item 1. Value from file specified by P4CONFIG

=item 2. Value from C<$ENV{P4PORT}>

=item 3. perforce:1666

=back

=item C<Client::SetProtocol( $protflag, $value )>

Set protocol options for this session. The most common
protocol option is the "tag" option which requests tagged
output format for commands which would otherwise get formatted
output. In API terms, this means the output comes through the
P4::UI::OutputStat() interface, instead of P4::UI::OutputInfo().

For example:

=over 4

C<< $client->SetProtocol(tag','') >>

=back

=item C<Client::SetUser( $username )>

Set your Perforce username. Defaults to:

=over 4

=item 1. Value from file specified by P4CONFIG

=item 2. Value from C<$ENV{P4USER}>

=item 3. OS username

=back

=back

=head1 API Versions

This extension has been built and tested on the Perforce 2000.2 API,
but should work with any recent version, certainly any release later
than and including 99.2.

=head1 LICENCE

Copyright (c) 1997-2001, Perforce Software, Inc.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the 
    above copyright notice, this list of conditions 
    and the following disclaimer.

2.  Redistributions in binary form must reproduce 
    the above copyright notice, this list of conditions 
    and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL PERFORCE SOFTWARE, INC. BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 AUTHOR

Tony Smith, Perforce Software ( tony@perforce.com )

=head1 SEE ALSO

perl(1), P4::UI(3), Perforce API documentation.

=cut
