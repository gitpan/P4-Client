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

$self->{CC} 		= "c++";
$self->{LD} 		= "c++";

$self->{DEFINE} .= " -Dsolaris";
$self->{LIBS} = [ "-lsocket", "-lnsl" ];

my $osver = `uname -r`;
if ( $osver eq "5.5" )
{
    $self->{DEFINE} .= " -DOS_SOLARIS25 ";
    unshift( @{ $self->{LIBS} },  "/usr/ucblib/libucb.a" );
}
elsif ( $osver eq "5.6" )
{
    $self->{DEFINE} .= " -DOS_SOLARIS26 ";
}
elsif ( $osver =~ /5.(\d+)/ )
{
    $self->{DEFINE} .= " -DOS_SOLARIS2$1 -Dconst_char='const char'";
}
