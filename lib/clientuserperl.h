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

/*
 * Defines the ClientUser derived class used by the perl interface
 */

class ClientUserPerl : public ClientUser
{
    public:
			ClientUserPerl( SV * perlUI );

	virtual void	ErrorPause( char *errBuf, Error *e );
	virtual void 	HandleError( Error *err );
	virtual void	InputData( StrBuf *strbuf, Error *e );
	virtual void 	OutputError( char *errBuf );
	virtual void	OutputInfo( char level, const_char *data );
	virtual void	OutputStat( StrDict *varList );
	virtual void 	OutputText( const_char *data, int length );
	virtual void	Prompt( const StrPtr &msg, StrBuf &rsp, 
				int noEcho, Error *e );
	virtual void	Edit( FileSys *f1, Error *e );
	virtual void	Diff( FileSys *f1, FileSys *f2, int doPage,
	       			char *diffFlags, Error *e );

		void	DebugLevel( int d ) { debug = d; }

    private:
		void 	DictToHash( StrDict *d, HV *hv );
		void	SplitKey( const StrPtr *key, StrBuf &base, StrBuf &index );
		void	InsertItem( HV *hv, const StrPtr *var, const StrPtr *val );
		void	HashToForm( HV *hv, StrBuf *b );
		HV *	FlattenHash( HV *hv );

    private:
	SV*		perlUI;
	int		debug;

};


