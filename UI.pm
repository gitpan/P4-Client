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
				$^O eq "MSWin32" ? 
					"notepad" : 
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
	print( STDERR $err );
}


# Tagged output format
sub OutputStat
{
	my ($self, $hash ) = @_;

	foreach my $key ( sort keys %$hash )
	{
	    if ( ref( $hash->{ $key } ) )
	    {
		# Nested element
		print( "... $key\n" );
		foreach my $item ( @{ $hash->{ $key } } )
		{
		    print( "... ... $item\n" );
		}
	    }
	    else
	    {
		print("... $key ", $hash->{ $key }, "\n" );
	    }
	}
	print("\n");
}

# Write a text buffer to stdout
sub OutputText($$)
{
	my ($self, $text, $len ) = @_;
	printf( "%*s", $len, $text );
}


# Prompt the user for input
sub Prompt($)
{
	my $self = shift;
	my $prompt = shift;

	print("$prompt" );
	return <>;
}


#
# Function to diff two files. This default implementation does nothing of
# great use and is intended to be overridden in derived classes. It's only
# called if you have previously called P4::Client::DoPerlDiffs() as by
# default the diff output will go through the OutputText() interface.
#
sub Diff($$$$)
{
    my $self 		= shift;
    my $f1		= shift;
    my $f2		= shift;
    my $diffFlags	= shift;
    my $differ		= shift;

    if ( $differ )
    {
	print( "$f1 and $f2 differ\n" );
    }
    else
    {
	print( "$f1 and $f2 are the same\n" );
    }
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

=item C<new()>

	Constructor. The only method of this class you call
	directly.

=item C<Edit( $filename )>

	Method called when the Perforce server wants the client to
	edit a specform ( changespec, jobspec, clientspec etc.). 
	The default implementation simply invokes your chosen editor
	by checking the environment variables P4EDITOR and EDITOR
	before falling back on vi/notepad and hoping they're there.

=item C<ErrorPause( $message )>

	Called to alert the user to an error message which they
	must acknowledge before continuing. Default implementation
	prints the message on stdout and prompts the user to "Hit
	Return to continue".

=item C<InputData()>

	Used to read information directly from the user. Called
	in response to the "-i" flag to many Perforce commands.
	i.e. "p4 submit -i".

=item C<OutputInfo( $level, $data )>

	Writes data to stdout prefixed by $level occurances of 
	"..." 

=item C<OutputError( $error )>

	Blurt an error to stderr. The error message arrives 
	as preformatted text. 

=item C<OutputStat( $hashref )>

	Print the output of a command in tagged format. The tagged
	data is passed as a hash reference for ease of use. Multi 
	line fields (such as mappings) are presented as array
	references within the hash. i.e. in a clientspec, the 
	View field in the form is normally transmitted by Perforce 
	as a sequence of fields: "View0", "View1", etc. P4::UI gets
	these as a single "View" member of the hash which is itself 
	an array reference containing the view records in order.

=item C<OutputText( $text, $length )>

	Prints $length bytes of $text on STDOUT

=item C<Prompt( $prompt )>

	Prints the prompt string $prompt and then reads a line
	of input from the user returning the input line.

=item C<Diff( $f1, $f2, $flags, $differ )>

	Diff two files manually. The default implementation of this method
	does nothing of any great use. It's intended to be overridden
	in subclasses for users who want to do the diffs themselves. 
	This method will not be invoked unless you have previously
	called the P4::Client::DoPerlDiffs() method to specify your
	prediliction for doing things the hard way. Otherwise diff
	output goes out through OutputText().

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
