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
#include "XSUB.h"

#ifdef Error
// Defined by older versions of Perl to be Perl_Error
# undef Error
#endif
#include "clientuserperl.h"

/*
 * The architecture of this extension is relatively complex. The main
 * class is P4::Client which is a blessed hash containing:
 *
 *	1. a pointer to the real ClientApi object.
 *	2. a pointer to a per instance Error object
 *	3. an integer to track the number of Init/Final calls
 *
 * This makes the implementation here more complex than I'd like it to be
 * but bundling these three things together makes it so much more usable.
 * 
 * As the Perforce API is callback based, this class doesn't have anything
 * to do with client output. ClientApi::Run() ends up calling member functions
 * of a ClientUser derived object to interact with the user. ClientUserPerl
 * provides this interface and transfers the C++ callback into a Perl
 * callback. 
 *
 * The real interaction with the user is then dealt with in Perl space by
 * the P4::UI module. As it's all OO based, derive a class from P4::UI to
 * customise the interaction.
 */


/*
 * Local function to get at the data stored in the hash
 */
static int ExtractData( SV *obj, Error **e, ClientApi **c, SV **i )
{
	SV	**tmp;

	if (!(sv_isobject((SV*)obj) && sv_derived_from((SV*)obj,"P4::Client")))
	{
	    warn("Not a P4::Client object!" );
	    return 0;
	}

	tmp = hv_fetch( (HV *)SvRV(obj), "Error", 5, 0 );
	*e = ( Error * ) SvIV( *tmp );
	tmp = hv_fetch( (HV*)SvRV(obj), "Client", 6, 0 );
	*c = ( ClientApi *) SvIV( *tmp );
	tmp = hv_fetch( (HV*) SvRV(obj), "InitCount", 9, 0 );
	*i = *tmp;
	return 1;
}


/*
 * Local function to get hold of just the ClientApi pointer from the hash
 */
static ClientApi *ExtractClient( SV *obj )
{
	SV	**tmp;

	if (!(sv_isobject((SV*)obj) && sv_derived_from((SV*)obj,"P4::Client")))
	{
	    warn("Not a P4::Client object!" );
	    return NULL;
	}
	if ( ! SvROK( obj ) )
	{
	    warn( "Can't dereference object!!!" );
	    return NULL;
	}
	tmp = hv_fetch( (HV *)SvRV(obj), "Client", 6, 0 );
	return ( ClientApi *) SvIV( *tmp );
}


MODULE = P4::Client		PACKAGE = P4::Client

SV *
new( CLASS )
	char *CLASS;

	INIT:
	    HV		*myself;
	    HV		*stash;
	    Error	*e;
	    ClientApi	*c;
	    SV		*initdone;
	    SV		*tmp;

	CODE:
	    /*
	     * Create a new HV and put inside it a pointer to a new
	     * ClientApi object. We also need an Error * and we need
	     * a flag to track whether or not the Init() suceeded so
	     * we know to call Final() in the DESTROY XSUB
	     */
	    myself = newHV();

	    c = new ClientApi();
	    e = new Error();

	    /* Put the client in the hash */
	    tmp = newSViv( (I32) c );
	    hv_store( myself, "Client", 6, tmp, 0 );

	    /* Put the error object in the hash */
	    tmp = newSViv( (I32)e );
	    hv_store( myself, "Error", 5, tmp, 0 );

	    /* Now put a flag in the hash for Init/Final testing */
	    tmp = newSViv( 0 );
	    hv_store( myself, "InitCount", 9, tmp, 0 );

	    /* Return a blessed reference to the hash */
	    RETVAL = newRV_noinc( (SV * )myself );
	    stash = gv_stashpv( CLASS, TRUE );
	    sv_bless( (SV *)RETVAL, stash );

	OUTPUT:
	    RETVAL

void
DESTROY( THIS )
	SV	*THIS

	INIT:
	    Error	*e;
	    ClientApi	*c;
	    SV		*count;

	CODE:
	    if ( ! ExtractData( THIS, &e, &c, &count ) )
		XSRETURN_UNDEF;
	
	    if ( SvIV( count ) )
		c->Final( e );
	
	    delete e;
	    delete c;
	    

int
Dropped( THIS )
	SV	*THIS
	INIT:
	    ClientApi	*c;
	CODE:
	    c = ExtractClient( THIS );
	    if ( c ) XSRETURN_UNDEF;
	    RETVAL = c->Dropped();
	OUTPUT:
	    RETVAL

void
Final( THIS )
	SV 	*THIS

	INIT:
	    Error	*e;
	    ClientApi	*c;
	    SV		*count;

	CODE:
	    if ( ! ExtractData( THIS, &e, &c, &count ) )
		XSRETURN_UNDEF;

	    if ( SvIV( count ) )
	    {
	        c->Final( e );
		sv_setiv( count, SvIV(count) - 1 );
	    }
	    else
	    {
		warn( "Can't call Final() when you haven't called Init()" );
	    }

SV *
GetClient( THIS )
	SV 	*THIS

	INIT:
	    ClientApi	*c;
	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;

	    StrPtr cl = c->GetClient();
	    RETVAL = newSVpv( cl.Text(), 0 );
	OUTPUT:
	    RETVAL

SV *
GetCwd( THIS )
	SV 	*THIS

	INIT:
	    ClientApi	*c;
	CODE:
            c = ExtractClient( THIS );
            if ( ! c )
		XSRETURN_UNDEF;

	    StrPtr cwd = c->GetCwd();
	    RETVAL = newSVpv( cwd.Text(), 0 );
	OUTPUT:
	    RETVAL

SV *
GetHost( THIS )
	SV 	*THIS

	INIT:
	    ClientApi	*c;
	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;

	    StrPtr h = c->GetHost();
	    RETVAL = newSVpv( h.Text(), 0 );
	OUTPUT:
	    RETVAL

SV *
GetPassword( THIS )
	SV 	*THIS

	INIT:
	    ClientApi	*c;
	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;

	    StrPtr p = c->GetPassword();
	    RETVAL = newSVpv( p.Text(), 0 );
	OUTPUT:
	    RETVAL

SV *
GetPort( THIS )
	SV 	*THIS

	INIT:
	    ClientApi	*c;
	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;

	    StrPtr p = c->GetPort();
	    RETVAL = newSVpv( p.Text(), 0 );
	OUTPUT:
	    RETVAL

SV *
GetUser( THIS )
	SV 	*THIS

	INIT:
	    ClientApi	*c;
	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;

	    StrPtr u = c->GetUser();
	    RETVAL = newSVpv( u.Text(), 0 );
	OUTPUT:
	    RETVAL


SV *
Init( THIS )
	SV 	*THIS

	INIT:
	    ClientApi	*c;
	    Error 	*e;
	    SV		*count;

	CODE:
	    if ( ! ExtractData( THIS, &e, &c, &count ) )
	       	XSRETURN_NO;

	    if ( SvIV( count ) )
	    {
		warn( "P4::Client - client has already been initialized" );
		XSRETURN_YES;
	    }

	    e->Clear();
	    c->Init( e );
	    RETVAL = newSViv( ! e->Test() );
	    if ( ! e->Test() )
		sv_setiv( count, SvIV( count ) + 1 );

	OUTPUT:
	    RETVAL

void
Run( THIS, uiref, cmd, ... )
	SV *THIS
	SV *uiref
	SV *cmd
	INIT:
	    ClientApi	*c;
	    Error	*e;
	    SV		*count;

	    AV		*args;
	    I32		va_start = 3;
	    I32		debug = 0;
	    I32		argc;
	    I32		stindex;
	    I32		argindex;
	    STRLEN		len = 0;
	    char		*currarg;
	    char		**cmdargs = NULL;
	    SV		*sv;
	    ClientUserPerl	*ui = NULL;

	CODE:
	    if ( ! ExtractData( THIS, &e, &c, &count ) )
	    {
		warn("Not a P4::Client object" );
	       	XSRETURN_UNDEF;
	    }

	    /*
	     * First check that the client has been initialised. Otherwise
	     * the result tends to be a SEGV
	     */
	    if ( ! SvIV( count ) )
	    {
		warn("P4::Client::Run() - Client has not been initialised");
		XSRETURN_UNDEF;
	    }

	    /*
	     * Set up the ClientUserPerl interface
	     */
	    if (sv_isobject(uiref) && sv_derived_from( uiref, "P4::UI") )
		ui = new ClientUserPerl( uiref );
	    else 
	    {
		warn("P4::Client::Run() - uiref is not a P4::UI object");
		XSRETURN_UNDEF;
	    };
	
	    if ( items > va_start )
	    {
		argc = items - va_start;
		New( 0, cmdargs, argc, char * );
		for ( stindex = va_start, argindex = 0; 
			argc; 
			argc--, stindex++, argindex++ )
		{
		    if ( SvPOK( ST(stindex) ) )
		    {
			currarg = SvPV( ST(stindex), len );
			cmdargs[argindex] =  currarg ;
		    }
		    else if ( SvIOK( ST(stindex) ) )
		    {
			/*
			 * Be friendly and convert numeric args to 
		         * char *'s. Use Perl to reclaim the storage.
		         * automatically by declaring them as mortal SV's
		         */
			char	buf[32];
			STRLEN	len;
			sprintf(buf, "%d", SvIV( ST( stindex ) ) );
			sv = sv_2mortal(newSVpv( buf, 0 ));
			currarg = SvPV( sv, len );
			cmdargs[argindex] = currarg;
		    }
		    else
		    {
			/*
		         * Can't handle other arg types
		         */
		        croak( "Invalid argument to ClientApi::Run" );
		    }
		}
	    }

	    len = 0;
	    currarg = SvPV( cmd, len );
	    if ( debug )
	    {
	        for ( int i = 0; i < items - va_start; i++ )
	        {
		    printf("[ClientApi::Run] Arg[%d] = %s\n", i, cmdargs[i] );
	        }
	    }
	    c->SetArgv( items - va_start, cmdargs );
	    c->Run( currarg, ui );
	    if ( ui )delete ui;
	    if ( cmdargs )Safefree( cmdargs );

void
SetClient( THIS, clientName )
	SV	*THIS
	char 	*clientName

	INIT:
	    ClientApi	*c;

	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;

	    c->SetClient( clientName );


void
SetCwd( THIS, cwd )
	SV	*THIS
	char *cwd

	INIT:
	    ClientApi	*c;

	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;
	
	    c->SetCwd( cwd );


void
SetHost( THIS, hostname )
	SV	*THIS
	char *hostname

	INIT:
	    ClientApi	*c;

	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;

	    c->SetHost( hostname );

void
SetPassword( THIS, password )
	SV	*THIS
	char *password
	INIT:
	    ClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;
	    
	    c->SetPassword( password );



void
SetPort( THIS,  address )
	SV	*THIS
	char *address

	INIT:
	    ClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;

	    c->SetPort( address );

void
SetProtocol( THIS, protocol, value )
	SV	*THIS
	char *protocol
	char *value

	INIT:
	    ClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;

	    c->SetProtocol( protocol, value );

void
SetUser( THIS, username )
	SV	*THIS
	char *username

	INIT:
	    ClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if ( ! c )
	       	XSRETURN_UNDEF;

	    c->SetUser( username );

