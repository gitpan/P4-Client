# Copyright (c) 1997-2004, Perforce Software, Inc.  All rights reserved.
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

use ExtUtils::MakeMaker;
use English;
use Cwd 'abs_path';
use strict;

#$ExtUtils::MakeMaker::Verbose = 1;

#
# This sub adds the Perforce API path to the header includes and libs 
# used by the compiler. It's called by WriteMakefile.
#
sub config_sub
{
	my $class = shift;
	my $href = shift;

	# First warn them about potential build problems
	print <<EOF;

Warning: This extension uses C++ and requires that you use the C++ 
	 compiler to compile the XSUB file ( normally just a C compiler
	 is required ). 

	 If your build fails with a plethora of errors, then check
	 two things: 

	 1. That you have defined the correct OS_xxxxx macro for your
	    platform ( see the Perforce API documentation for more info )

	 2. That the correct compilers are being used.

	 3. That you're using the correct build of the Perforce API. 

	 See hints/linux.pl to see how it should be done.

EOF
	# Now find that API!
	my $flags = {};
	print <<EOF;

This extension requires the Perforce API in order to be built. If you
do not yet have the API files, then download them from ftp://ftp.perforce.com
before continuing.

EOF

	# Get the path to the Perforce API
	my $apipath = "";
	print( "Where is the Perforce API to be found: " );
	$apipath = <STDIN>;
	$apipath =~ s/\n//;

	# Filthy support for ~/ type paths ( NOT ~user/ though! )
	$apipath =~ s#\~/#$ENV{HOME}/#;
	$apipath = abs_path( $apipath );

	# These two aren't in the hints file because some variant of them is
	# needed on every OS so it's better to have it visible.
	$flags->{'LIBS'} = [];
	if( defined( $href->{LIBS} ) )
	{
	    my $libs = $href->{LIBS};
	    foreach my $libset (@$libs )
	    {
		push( @{$flags->{LIBS}}, 
			"-L$apipath -lclient -lrpc -lsupp $libset" );
		print("Added P4 libs to $libset\n" );
	    }
	}
	else
	{
	    push( @{$flags->{LIBS}},  "-L$apipath -lclient -lrpc -lsupp" );
	}
	$flags->{ 'INC' }		= "-I$apipath -Ilib";


	# Last thing to do is to get the address of their perforce 
	# server for the tests
	print <<EOF;

The test suite needs to know where your Perforce server is. The tests
are non-invasive and no new data will be added to your depot during
the tests

EOF
	print( "Enter the address of your Perforce server: [localhost:1666]: ");
	my $p4port = <STDIN>;
	$p4port =~ s/\n//;
	$p4port = "localhost:1666" if ( $p4port =~ /^$/ );

	open( IN, "test.pl.skel" ) or croak( "Can't open test.pl.skel! ");
	open( OUT, ">test.pl" ) or croak( "Can't create test.pl" );

	my $line;
	while ( $line = <IN> )
	{
	    $line =~ s/__P4PORT__/$p4port/g;
	    print( OUT $line );
	}
	close( IN );
	close( OUT );

	return $flags;
}

# Ensure that the clientuserperl interface gets built.
sub MY::postamble
{
'
$(MYEXTLIB): lib/Makefile
	cd lib && $(MAKE) $(PASSTHRU)
';
}

#*******************************************************************************
#* 			START OF MAIN SCRIPT
#*******************************************************************************

my %flags = (
	    'NAME'		=> 'P4::Client',
	    'VERSION_FROM'	=> 'Client.pm', # finds $VERSION
	    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
	    'MYEXTLIB'		=> 'lib/libp4$(LIB_EXT)',
	    'XSOPT'		=> '-C++ -prototypes',
	    'CONFIGURE'		=> \&config_sub,
	    'clean'		=> { FILES => 'test.pl' },
	);


WriteMakefile( %flags );

