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
package P4::UI;
use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK );

require Exporter;

@ISA = qw(Exporter );

@EXPORT_OK = qw( );

@EXPORT = qw(
);

sub new
{
	my $class = shift;
	my $self = {};		# Empty for now
	bless( $self, $class );
	return $self;
}

# Edit the specified file ( normally a change spec or client spec etc ).
sub Edit($)
{
	my $self = shift;
	my $filename = shift;

	my $editor = defined( $ENV{"P4EDITOR"} ) ? 
			$ENV{"P4EDITOR"} :
			defined( $ENV{"EDITOR"} ) ?
				$ENV{"EDITOR"} :
				"vi";

	system( "$editor $filename" );
}


# Get the user to read a message and hit return to continue
sub ErrorPause($)
{
	my ($self, $message) = @_;
	$self->OutputError( $message );
	$self->Prompt( "Hit return to continue ..." );
}

# Read data from the user. Inefficiently at the moment.
sub InputData
{
	my $input = "";
	my $line;
	while( 	$line = <> )
	{
	    $input .= $line;
	}
}

# Write out textual information from the server. $level indicates indentation.
sub OutputInfo($$)
{
	my ($self, $level, $data) = @_;
	for( ; $level; $level-- )
	{
	    print(".... ");
	}
	print( $data, "\n" );
}

#
# Write an error message to stdout. All error messages are delivered to the
# Perl API ready formatted rather than in their structured form because it's
# (a) too complicated and (b) not worth it to do anything more sophisticated.
#
sub OutputError($)
{
	my ($self, $err) = @_;
	print( $err );
}


# Tagged output format
sub OutputStat
{
	my ($self, $hash ) = @_;
	foreach my $key ( sort keys %$hash )
	{
	    print("... $key ", $hash->{ $key }, "\n" );
	}
	print("\n");
}

# Write a text buffer to stdout
sub OutputText($$)
{
	my ($self, $text, $len ) = @_;
	print( $text );		# Ignore length unless it becomes an issue
}


# Prompt the user for input
sub Prompt($)
{
	my $self = shift;
	my $prompt = shift;

	print("$prompt" );
	return <>;
}

1;

__END__

=head1 NAME

P4::UI - User interface object for Perforce API

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
  $client->Final();


=head1 DESCRIPTION

This module provides a skeleton user interface for Perforce commands. The
output from the Perforce server is simply written to stdout, and input
comes from stdin. In order to do anything clever, you will need to 
derive a subclass from P4::UI and override the appropriate methods.

=head2 EXPORTS

	UI::new()	- Create a new user interface object

=head1 METHODS

=over 4

=item C<UI::new()>

	Constructor. The only method of this class you call
	directly.

=back

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

perl(1), P4::Client(3), Perforce API documentation.

=cut
