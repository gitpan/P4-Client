#!/usr/bin/perl -w

#*******************************************************************************
#* 
#* First derive a class from P4::UI so we can override the default behaviour
#* with our own. Specifically, we want to cache the results of fstat's on
#* multiple files and allow the caller to iterate through them later.
#* 
#*******************************************************************************
package P4::Fstat;
use P4::UI;
use strict;
use vars qw( @ISA );

# Derive this class from P4::UI
@ISA = qw( P4::UI );

#
# Define a constructor for this class
#
sub new
{
	my $class = shift;
	my $self = new P4::UI;
	$self->{'Records'} = [];
	bless( $self, $class );
	return $self;
}

# 
# p4 fstat produces tagged output which is printed by the OutputStat
# method in P4::UI so override that to get our own behaviour. P4::Client
# arranges for the tagged output to be passed to this method as a hash,
# but it will get cleaned up on return so you have to copy the data if
# you want to save it.
#
sub OutputStat
{
	my $self = shift;
	my $record = shift;

	my $newrec = {};
	foreach my $key ( keys %$record )
	{
	    $newrec->{ $key } = $record->{ $key };
	}
	push( @{$self->{'Records'}}, $newrec );
	return;
}


#
# Fetch the next record from the result set. Returns undef when
# there are no more records remaining.
#
sub Fetch
{
	my $self = shift;
	
	if ( scalar( @{$self->{'Records'}} ) )
	{
	    return ( shift( @{$self->{'Records'}} ) );
	}
	return undef;
}

#
# Return all remaining records at once in an array
# 
sub Records
{
	my $self = shift;
	return @{$self->{'Records'}};
}

#
# Can be used to flush the rest of the results if you no longer want them
#
sub Flush
{
	my $self = shift;
	$self->{'Records'} = ();
}


#*******************************************************************************
#*
#* Now we go back to the main package and start execution.
#*
#*******************************************************************************
package main;
use Carp;
use P4::Client;

my $p4 = new P4::Client;
my $ui = new P4::Fstat;

$p4->Init() or croak( "Can't connect to Perforce server" );


# Example call showing the use of the Records() method for getting
# the results.
$p4->Fstat( $ui, "..." );
foreach my $file ( $ui->Records() )
{
	print("Found file: ", $file->{'depotFile'}, "\n" );
}

# Now run it again, but iterate through the records counting them
my $rec;
my $count = 0;
$p4->Fstat( $ui, "..." );

$count++ while ( $rec = $ui->Fetch() );

print( "\nCounted $count files\n\n" );
