/*

Copyright (c) 1997-2001, Perforce Software, Inc.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTR
IBUTORS "AS IS"
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
#include "spec.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef Error
// Defined for unknown reasons by old versions of Perl to be Perl_Error
# undef Error
#endif

#include "clientuserperl.h"

#ifdef PERL_REVISION
# define USE_NEW_PERL_API
#endif

#ifndef dTHX
/*
 * Threaded Perl context macros aren't available in earlier Perl versions
 */
# define dTHX 	1
#endif

static void HashToForm( HV *hv, StrBuf *b );
static void DictToHash( StrDict *d, HV *hv );
static int GetBase( const StrPtr &key, StrBuf &base );
static HV * FlattenHash( HV *hv );

void
ClientUserPerl::Edit( FileSys *f1, Error *e )
{
	dTHX;
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
	dTHX;
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
	dTHX;
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
	int	useHash = 0;

	dTHX;
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
	if ( ! n )
	{
	    PUTBACK;
	    return;
	}

	SV *sv = POPs;
	HV *hv;

	if ( SvROK( sv ) )
	{
	    // We've been passed a reference - hopefully to a hash
	    hv = (HV *)SvRV( sv );
	    useHash = 1;
	}
	else if ( SvTYPE( sv ) == SVt_PV )
	{
	    strbuf->Set( POPp );
	}
	else if ( SvTYPE( sv ) == SVt_PVHV )
	{
	    hv = (HV *)sv;
	    useHash = 1;
	}
	else
	{
	    warn( "Invalid data returned from InputData() method" );
	}

	if( useHash )
	{

	    /*
	     * If the hash contains a "specdef" member, then it contains
	     * a form. We Format the form into a StrBuf and return that
	     * to our caller
	     */

	    SV 	**t = hv_fetch( hv, "specdef", 7, 0 );

	    if ( t ) 
	    {
		sv = *t;
		HashToForm( hv, strbuf );
	    }
	    else
	    {
		warn( "Can't convert hashref into a form. No spec supplied" );
	    }
	}

	PUTBACK;
	FREETMPS;
	LEAVE;
}

void 	
ClientUserPerl::OutputError( char *errBuf )
{
	dTHX;
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
	dTHX;
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
	HV		*hv;
	SV		*href;
	StrPtr		var, val;
	StrDict		*input = varList;
	StrPtr		*data = varList->GetVar( "data" );
	StrPtr		*spec = varList->GetVar( "specdef" );
	SpecDataTable	specData;
	Error		e;

	// Enter new Perl scope
	dTHX;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	// Create a new HV and make it mortal
	hv = newHV();
	sv_2mortal( (SV *)hv );

	/*
	 * If both spec and data are defined, then the user has set both the
	 * "tag" and "specstring" protocol options so we do them the 
	 * favour of parsing the spec here and presenting the parsed
	 * spec as a hash of key->value pairs. If not, then we just
	 * produce a direct hash from the StrDict object.
	 */

	if ( spec && data )
	{
	    Spec s( spec->Text(), "" );

	    s.Parse( data->Text(), &specData, &e );
	    if ( e.Test() )
	    {
		HandleError( &e );
		return;
	    }
	    input = specData.Dict();
	    input->SetVar( "specdef", spec->Text() );
	}

	// Now store the rest
	DictToHash( input, hv );

	// Now call the perl sub and pass a ref to the HV as its arg
	href = newRV( (SV *)hv );
	XPUSHs( perlUI );
	XPUSHs( href );
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
	dTHX;
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

	dTHX;
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

/*
 * Convert a dictionary to a hash. Numbered elements are converted
 * into an array member of the hash.
 */

void
DictToHash( StrDict *d, HV *hv )
{
    AV		*av = 0;
    SV		*rv = 0;
    SV		**svp = 0;
    int		i;
    int		seq;
    StrBuf	key;
    StrPtr	var, val;
    StrPtr	*data = d->GetVar( "data" );

    for( i = 0; d->GetVar( i, var, val ); i++ )
    {
	if( var == "func" ) continue;

	seq = GetBase ( var, key );
	if ( seq < 0 )
	{
	    hv_store( hv, var.Text(), var.Length(), 
		 newSVpv( val.Text(), val.Length() ), 0 );
	}
	else
	{
	    if ( seq == 0 )
	    {
		av = newAV();
		hv_store( hv, key.Text(), key.Length(), newRV( (SV*)av) ,0 );
	    }

	    svp = hv_fetch( hv, key.Text(), key.Length(), 0 );
	    if ( ! svp ) 
	    {
		StrBuf	msg;
		msg.Set( "Key (" );
		msg.Append( key.Text() );
		msg.Append( ") not found in hash!" );
		warn( msg.Text() );
		continue;
	    }

	    if ( ! SvROK( *svp ) )
	    {
		StrBuf	msg;
		msg.Set( "Key (" );
		msg.Append( key.Text() );
		msg.Append( ") not a reference!" );
		warn( msg.Text() );
		continue;
	    }

	    av = (AV *) SvRV( *svp );
	    av_store( av, seq, newSVpv( val.Text(), 0) );
	}
    }
}

/*
 * Given a key name, work out its base. i.e. for View0, View1, View10 etc.
 * the base is "View". Returns the sequence number or -1 if there is none.
 */

int
GetBase( const StrPtr &key, StrBuf &base )
{
    int i = 0;

    base = key;
    for ( i = 0; i < key.Length(); i++ )
	if ( isdigit( key[ i ] ) )
	    base.Set( key.Text(), i );

    if ( base == key ) return -1;

    StrBuf seq;
    seq.Set( key.Text() + i - 1 );

    return seq.Atoi();
}


void
HashToForm( HV *hv, StrBuf *b )
{
    SV	**t = hv_fetch( hv, "specdef", 7, 0 );
    SV	*specstr = *t;
    HV	*flatHv = 0;

    if ( ! SvPOK( specstr ) )
    {
	warn( "specdef member is not a string" );
	return;
    }

    /*
     * Also need now to go through the hash looking for AV elements
     * as they need to be flattened before parsing. Yuk!
     */
    flatHv = FlattenHash( hv );

    SpecDataTable	specData;
    Spec		s( SvPV( specstr, PL_na ), "" );

    char	*key;
    SV		*val;
    I32		klen;

    for ( hv_iterinit( flatHv ); val = hv_iternextsv( flatHv, &key, &klen ); )
    {
	if ( !SvPOK( val ) ) continue;
	specData.Dict()->SetVar( key, SvPV( val, PL_na ) );
    }

    s.Format( &specData, b );
}

// Flatten array elements in a hash into something Perforce can parse.

HV * 
FlattenHash( HV *hv )
{
    HV 		*fl;
    SV		*val;
    char	*key;
    I32		klen;

    fl = (HV *)sv_2mortal( (SV *)newHV() );
    for ( hv_iterinit( hv ); val = hv_iternextsv( hv, &key, &klen ); )
    {
	if ( SvROK( val ) && ( SvTYPE( SvRV( val ) ) == SVt_PVAV ) )
	{
	    // Flatten this array by constructing keys from the parent
	    // hash key and the array index
	    AV	*av = (AV *)SvRV( val );
	    for ( int i = 0; i <= av_len( av ); i++ )
	    {
		StrBuf	newKey;

		SV	**elem = av_fetch( av, i, 0 );
		newKey.Set( key );
		newKey << i;

		hv_store( fl, newKey.Text(), newKey.Length(), *elem, 0 );
	    }
	}
	else
	{
	    // Just store the element as is
	    hv_store( fl, key, klen, val, 0 );
	}
    }
    return fl;
}
