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

/*
 * Include math.h here because it's included by some Perl headers and on
 * Win32 it must be included with C++ linkage. Including it here prevents it
 * from being reincluded later when we include the Perl headers with C linkage.
 */
#ifdef OS_NT
#  include <math.h>
#endif

#include "clientapi.h"
#include "spec.h"

/* When including Perl headers, make sure the linkage is C, not C++ */

extern "C" 
{
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

/*******************************************************************************
 * Sort out Perl oddities.
 ******************************************************************************/

#ifdef Error
// Defined for unknown reasons by old versions of Perl to be Perl_Error
# undef Error
#endif

/*
 * Later versions of perl have a different calling interface
 */

#ifdef PERL_REVISION
# define PERL_CALL_METHOD( method, ctx ) call_method( method, ctx )
#else
# define PERL_CALL_METHOD( method, ctx ) perl_call_method( method, ctx )
#endif

#ifndef dTHX
/*
 * Threaded Perl context macros aren't available in earlier Perl versions
 */
# define dTHX 	1
#endif

/*******************************************************************************
 * Now proceed with the normal stuff
 ******************************************************************************/

#include "clientuserperl.h"


ClientUserPerl::ClientUserPerl( SV * perlUI )
{ 
    this->perlUI = perlUI; 
    debug = 0;
}

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

	PERL_CALL_METHOD( "Edit", G_VOID );

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

	PERL_CALL_METHOD( "ErrorPause", G_VOID );

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

	PERL_CALL_METHOD( "OutputError", G_VOID );

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

	n = PERL_CALL_METHOD( "InputData", G_SCALAR );

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
	    strbuf->Set( SvPV( sv, PL_na ) );
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

	PERL_CALL_METHOD( "OutputError", G_VOID );

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

	PERL_CALL_METHOD( "OutputInfo", G_VOID );

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

	if ( debug )
	    printf( "OutputStat: starting to parse data\n" );

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
	    if ( debug )
		printf( "OutputStat: spec and data both defined\n" );
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
	if ( debug )
	    printf( "OutputStat: Converting dictionary to hash\n" );

	DictToHash( input, hv );

	if ( debug )
	    printf( "OutputStat: Conversion done.\n" );


	// Now call the perl sub and pass a ref to the HV as its arg
	href = sv_2mortal( newRV( (SV *)hv ) );
	XPUSHs( perlUI );
	XPUSHs( href );
	PUTBACK;

	PERL_CALL_METHOD( "OutputStat", G_VOID );

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

	PERL_CALL_METHOD( "OutputText", G_VOID );

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

	n = PERL_CALL_METHOD( "Prompt", G_SCALAR );

	// Clean up stack for return
	SPAGAIN;
	if ( n == 1 )
	    rsp.Set( POPp );

	PUTBACK;
	FREETMPS;
	LEAVE;
}

void	
ClientUserPerl::Diff( FileSys *f1, FileSys *f2, int doPage,
	       			char *diffFlags, Error *e )
{
	dTHX;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);

	/*
	 * Note: ClientUser::Diff() is not invoked by the server unless
	 *	the MD5 sum of the client file differs from that of the
	 *	server file, so the check below is probably redundant. It's
	 *	included here in case this behaviour varies across server
	 *	versions (past and future).
	 */

        int differs = f1->Compare( f2, e );

        XPUSHs( perlUI );
        XPUSHs( sv_2mortal( newSVpv( f1->Name(), 0 ) ) );
        XPUSHs( sv_2mortal( newSVpv( f2->Name(), 0 ) ) );
        XPUSHs( sv_2mortal( newSVpv( diffFlags, 0 ) ) );
        XPUSHs( sv_2mortal( newSViv( differs ) ) );
        PUTBACK;

        PERL_CALL_METHOD( "Diff", G_VOID );

        // Clean up stack for return
        SPAGAIN;
        PUTBACK;
        FREETMPS;
        LEAVE;
}


/*
 * Convert a dictionary to a hash. Numbered elements are converted
 * into an array member of the hash.
 */

void
ClientUserPerl::DictToHash( StrDict *d, HV *hv )
{
    AV		*av = 0;
    SV		*rv = 0;
    SV		**svp = 0;
    int		i;
    int		seq;
    StrBuf	key;
    StrRef	var, val;
    StrPtr	*data = d->GetVar( "data" );

    for( i = 0; d->GetVar( i, var, val ); i++ )
    {
	if( var == "func" ) continue;
	InsertItem( hv, &var, &val );
    }
}

/*
 * Split a key into its base name and its index. i.e. for a key "how1,0"
 * the base name is "how" and they index is "1,0"
 */

void
ClientUserPerl::SplitKey( const StrPtr *key, StrBuf &base, StrBuf &index )
{
    int i = 0;

    base = *key;
    index = "";
    for ( i = 0; i < key->Length(); i++ )
    {
	if ( isdigit( (*key)[ i ] ) )
	{
	    base.Set( key->Text(), i );
	    index.Set( key->Text() + i );
	    break;
	}
    }
}

/*
 * Insert an element into the response structure. The element may need to
 * be inserted into an array nested deeply within the enclosing hash.
 */

void
ClientUserPerl::InsertItem( HV *hv, const StrPtr *var, const StrPtr *val )
{
    SV		**svp = 0;
    AV		*av = 0;
    StrBuf	base, index;
    StrRef	comma( "," );

    if ( debug )
	printf( "\tInserting key %s, value %s \n", var->Text(), val->Text() );

    SplitKey( var, base, index );

    if ( debug )
	printf( "\t\tbase=%s, index=%s\n", base.Text(), index.Text() );


    // If there's no index, then we insert into the top level hash 
    // and we're out easy
    if ( index == "" )
    {
	if ( debug )
	    printf( "\tCreating new scalar hash member %s\n", base.Text() );
	hv_store( hv, base.Text(), base.Length(), 
	     newSVpv( val->Text(), val->Length() ), 0 );
	return;
    }

    //
    // Get or create the parent AV from the hash.
    //
    svp = hv_fetch( hv, base.Text(), base.Length(), 0 );
    if ( ! svp ) 
    {
	if ( debug )
	    printf( "\tCreating new array hash member %s\n", base.Text() );

	av = newAV();
	hv_store( hv, base.Text(), base.Length(), newRV( (SV*)av) ,0 );
    }

    if ( svp && ! SvROK( *svp ) )
    {
	StrBuf	msg;
	msg.Set( "Key (" );
	msg.Append( base.Text() );
	msg.Append( ") not a reference!" );
	warn( msg.Text() );
	return;
    }

    if ( svp && SvROK( *svp ) )
	av = (AV *) SvRV( *svp );

    // The index may be a simple digit, or it could be a comma separated
    // list of digits. For each "level" in the index, we need a containing
    // AV and an HV inside it.
    if ( debug )
	printf( "\tFinding correct index level...\n" );

    for( const char *c = 0 ; c = index.Contains( comma ); )
    {
	StrBuf	level;
	level.Set( index.Text(), c - index.Text() );
	index.Set( c + 1 );

	// Found another level so we need to get/create a nested AV
	// under the current av. If the level is "0", then we create a new
	// one, otherwise we just pop the most recent AV off the parent
	
	if ( debug )
	    printf( "\t\tgoing down...\n" );

	svp = av_fetch( av, level.Atoi(), 0 );
	if ( ! svp )
	{
	    AV *tav = newAV();
	    av_store( av, level.Atoi(), newRV( (SV*)tav) );
	    av = tav;
	}
	else
	{
	    if ( ! SvROK( *svp ) )
	    {
		warn( "Not an array reference." );
		return;
	    }

	    if ( SvTYPE( SvRV( *svp ) ) != SVt_PVAV )
	    {
		warn( "Not an array reference." );
		return;
	    }

	    av = (AV *) SvRV( *svp );
	}
    }
    if ( debug )
	printf( "\tInserting value %s\n", val->Text() );

    av_push( av, newSVpv( val->Text(), 0 ) );
}


void
ClientUserPerl::HashToForm( HV *hv, StrBuf *b )
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
ClientUserPerl::FlattenHash( HV *hv )
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

		hv_store( fl, newKey.Text(), newKey.Length(), 
			SvREFCNT_inc(*elem), 0 );
	    }
	}
	else
	{
	    // Just store the element as is
	    hv_store( fl, key, klen, SvREFCNT_inc(val), 0 );
	}
    }
    return fl;
}
