/*

Copyright (c) 1997-2001, Perforce Software, Inc.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

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

*/

#include "clientapi.h"
#include "EXTERN.h"
#include "perl.h"

#ifdef Error
// Defined for unknown reasons by old versions of Perl to be Perl_Error
# undef Error
#endif

#include "clientuserperl.h"

#ifdef PERL_REVISION
# define USE_NEW_PERL_API
#endif


void
ClientUserPerl::Edit( FileSys *f1, Error *e )
{
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs( perlUI );
	XPUSHs( sv_2mortal( newSVpv( f1->Name(), 0 ) ) );
	PUTBACK;

#ifdef USE_NEW_PERL_API
	call_method( "Edit", G_VOID );
#else
	perl_call_method( "Edit", G_VOID );
#endif

	// Clean up stack for return
	SPAGAIN;
	PUTBACK;
	FREETMPS;
	LEAVE;
}


void	
ClientUserPerl::ErrorPause( char *errBuf, Error *e )
{
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs( perlUI );
	XPUSHs( sv_2mortal( newSVpv( errBuf, 0 ) ) );
	PUTBACK;

#ifdef USE_NEW_PERL_API
	call_method( "ErrorPause", G_VOID );
#else
	perl_call_method( "ErrorPause", G_VOID );
#endif

	// Clean up stack for return
	SPAGAIN;
	PUTBACK;
	FREETMPS;
	LEAVE;
}


void 	
ClientUserPerl::HandleError( Error *e )
{
	StrBuf	errBuf;

	e->Fmt( &errBuf );
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs( perlUI );
	XPUSHs( sv_2mortal( newSVpv( errBuf.Text(), errBuf.Length() ) ) );
	PUTBACK;

#ifdef USE_NEW_PERL_API
	call_method( "OutputError", G_VOID );
#else
	perl_call_method( "OutputError", G_VOID );
#endif

	// Clean up stack for return
	SPAGAIN;
	PUTBACK;
	FREETMPS;
	LEAVE;
}

void
ClientUserPerl::InputData( StrBuf *strbuf, Error *e )
{
	I32	n; 	/* Number of items returned */

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs( perlUI );
	PUTBACK;

#ifdef USE_NEW_PERL_API
	n = call_method( "InputData", G_SCALAR );
#else
	n = perl_call_method( "InputData", G_SCALAR );
#endif

	SPAGAIN;
	if ( n == 1 )
	    strbuf->Set( POPp );

	PUTBACK;
	FREETMPS;
	LEAVE;
}

void 	
ClientUserPerl::OutputError( char *errBuf )
{
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs( perlUI );
	XPUSHs( sv_2mortal( newSVpv( errBuf, 0 ) ) );
	PUTBACK;

#ifdef USE_NEW_PERL_API
	call_method( "OutputError", G_VOID );
#else
	perl_call_method( "OutputError", G_VOID );
#endif

	// Clean up stack for return
	SPAGAIN;
	PUTBACK;
	FREETMPS;
	LEAVE;
}

void	
ClientUserPerl::OutputInfo( char level, const_char *data )
{
	int	lev;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	// Put args on stack
	lev = level - '0';
	XPUSHs( perlUI );
	XPUSHs( sv_2mortal( newSViv( lev ) ) );

	// Must cast to char * to keep perl 5.5 happy
	XPUSHs( sv_2mortal( newSVpv( (char *)data, 0 ) ) );
	PUTBACK;

#ifdef USE_NEW_PERL_API
	call_method( "OutputInfo", G_VOID );
#else
	perl_call_method( "OutputInfo", G_VOID );
#endif

	// Clean up stack for return
	SPAGAIN;
	PUTBACK;
	FREETMPS;
	LEAVE;
}


/*
 * Tagged output format. For this we create a hash mapping the tags
 * to the values. Then we pass the HV to the perl sub
 */
void	
ClientUserPerl::OutputStat( StrDict *varList )
{
	HV	*data;
	SV	*sv;
	int i;
	StrBuf msg;
	StrPtr var, val;

	
	// Enter new Perl scope
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	// Create a new HV and make it mortal
	data = newHV();
	sv_2mortal( (SV *)data );

	for( i = 0; varList->GetVar( i, var, val ); i++ )
	{
	    if( var == "func" ) continue;
	    hv_store( data, var.Text(), var.Length(), 
	    	sv_2mortal( newSVpv( val.Text(),0)) ,0 );
	}

	// Now call the perl sub and pass a ref to the HV as its arg
	sv = newRV( (SV *)data );
	XPUSHs( perlUI );
	XPUSHs( sv );
	PUTBACK;

#ifdef USE_NEW_PERL_API
	call_method( "OutputStat", G_VOID );
#else
	perl_call_method( "OutputStat", G_VOID );
#endif

	SPAGAIN;
	PUTBACK;
	FREETMPS;
	LEAVE;
}


void
ClientUserPerl::OutputText( const_char *data, int length )
{
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	// Put args on stack
	XPUSHs( perlUI );
	XPUSHs( sv_2mortal( newSVpv( (char *)data, 0 ) ) );
	XPUSHs( sv_2mortal( newSViv( length ) ) );
	PUTBACK;

#ifdef USE_NEW_PERL_API
	call_method( "OutputText", G_VOID );
#else
	perl_call_method( "OutputText", G_VOID );
#endif

	// Clean up stack for return
	SPAGAIN;
	PUTBACK;
	FREETMPS;
	LEAVE;
}


/*
 * Prompts the user for input. If noEcho is true, then we call the 
 * ClientUser version as that deals with Terminal handling nicely.
 */
void	
ClientUserPerl::Prompt( const StrPtr &msg, StrBuf &rsp, 
				int noEcho, Error *e )
{
	int 	n;

	if ( noEcho )
	{
	    ClientUser::Prompt( msg, rsp, noEcho, e );
	    return;
	}

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	// Put args on stack
	XPUSHs( perlUI );
	XPUSHs( sv_2mortal( newSVpv( msg.Text(), msg.Length() ) ) );
	PUTBACK;

#ifdef USE_NEW_PERL_API
	n = call_method( "Prompt", G_VOID );
#else
	n = perl_call_method( "Prompt", G_VOID );
#endif

	// Clean up stack for return
	SPAGAIN;
	if ( n == 1 )
	    rsp.Set( POPp );

	PUTBACK;
	FREETMPS;
	LEAVE;
}


