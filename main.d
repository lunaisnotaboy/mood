module main ;

import std.stdio     ;
import std.process   ;
import std.path      ;
import std.string    ;
import std.file      ;
import std.array     ;
import std.conv      ;
import std.typecons  ;
import std.algorithm ;
import std.datetime  ;

int usage( string arg0 ) {
	switch ( arg0 ) {
		case "log"   : writeln( "Usage: " , helpLog ) ; break ;
		case "day"   : writeln( "Usage: " , helpDay ) ; break ;
		case "week"  : writeln( "Usage: " , helpLog ) ; break ;
		case "month" : writeln( "Usage: " , helpLog ) ; break ;
		case "year"  : writeln( "Usage: " , helpLog ) ; break ;
		case "all"   : writeln( "Usage: " , helpLog ) ; break ;
		case "edit"  : writeln( "Usage: " , helpLog ) ; break ;
		case "nohistory" :
			writeln( "No data yet! Use the 'log' command to log your mood" ) ;
			break ;
		default :
			writeln( "Usage: " , arg0 ,
			         " {log|day|week|month|year|all|edit|help|[ldwmyaeh]}" ) ;
			writeln( "Run '" , arg0 ,
			         " help' for more detailed documentation" ) ;
			break ;
	}
	return 0 ;
}

// help strings
const string helpLog = "log [1-10]" ;
const string helpDay = "day"        ;

string historyFile = "" ;

int main( string[] args ) {
	if ( args.length == 1 ) return args[0].usage ;

	historyFile = buildPath(
		environment.get( "XDG_DATA_HOME" , expandTilde( "~/.local/share" ) ) ,
		"mood-history"
	) ;

	switch ( args[1] ) {
		case "l" , "log"   : return log  ( args[2..$] ) ;
		case "d" , "day"   : return day  ( args[2..$] ) ;
		case "w" , "week"  : return week ( args[2..$] ) ;
		case "m" , "month" : return month( args[2..$] ) ;
		case "y" , "year"  : return year ( args[2..$] ) ;
		case "a" , "all"   : return all  ( args[2..$] ) ;
		case "e" , "edit"  : return edit ( args[2..$] ) ;
		case "h" , "help"  : return help ( args[2..$] ) ;
		default : return args[0].usage ;
	}
}

void abort(T...)( T args ) {
	import core.stdc.stdlib : exit ;
	stderr.writeln( args ) ;
	exit( 1 ) ;
}

// utility functions

void ensureHistoryFile() {
	try if ( ! exists( historyFile ) ) std.file.write( historyFile , "" ) ;
	catch (Throwable) abort( "Failed to create history file '" , historyFile ,
	                         "'.  Exiting" ) ;
}

alias Entry = Tuple!( string , "date" , string , "values" ) ;

Entry[] getHistory() {
	ensureHistoryFile ;
	return historyFile.readText.splitLines.map!( l => l.split( " " ) )
		.map!( a => Entry( a[0] , a[1] ) ).array ;
}

void save( Entry[] history ) {
	ensureHistoryFile ;
	std.file.write( historyFile ,
		history.map!( e => e.date ~ " " ~ e.values ).array.join( "\n" )
	) ;
}

string getToday() {
	return Clock.currTime.toLocalTime.toISOExtString[0..10] ;
}

Date todayDate() { return Date.fromISOExtString( getToday ) ; }

int[] getDays( int daysago ) {
	auto history = getHistory ;
	if ( history.length == 0 ) return [] ;

	auto today    = todayDate               ;
	auto firstDay = today - days( daysago ) ;
	auto entry    = history.length - 1      ;
	int[] values ;

	while ( today >= firstDay ) {
		if ( entry < 0 || entry >= history.length ) values ~= 0 ;
		else if ( history[entry].date == today.toISOExtString ) {
			values ~= cast(int)(
				history[entry].values.split( "," ).map!( to!int ).array.mean
			) ;
			entry -- ;
		} else values ~= 0 ;

		today -= days( 1 ) ;
	}
	return values.reverse ;
}

void graph( int[] values )
in ( std.algorithm.all!( v => v >= 0 && v <= 10 )( values ) ,
     "All values must be 1-10" ) {
	const string[] prefixes = [ ":D" , ":)" , ":|" , ":(" , ":C" ] ;
	const string[] colours = [
		"\x1b[32m" , "\x1b[34m" , "\x1b[35m" , "\x1b[33m" , "\x1b[31m"
	] ;
	const string reset = "\x1b[0m" ;

	alias Bar = Tuple!( int , int ) ; // min max
	Bar[] bars ;
	foreach ( ulong i , int v ; values ) {
		Bar bar = Bar( v , v ) ;
		if ( i > 0 )
			if ( values[ i - 1 ] < bar[0] - 1 && values[ i - 1 ] > 0 )
				bar[0] = values[ i - 1 ] + 1 ;
		if ( i < values.length - 1 )
			if ( values[ i + 1 ] < bar[0] - 1 && values[ i + 1 ] > 0 )
				bar[0] = values[ i + 1 ] + 1 ;
		bars ~= bar ;
	}

	// draw graph
	static foreach ( ulong l , int m ; [ 9 , 7 , 5 , 3 , 1 ] ) {
		write( colours[l] , prefixes[l] , " " ) ;
		foreach ( b ; bars ) {
			if      ( b[0] > m + 1 || b[1] < m ) write( " " ) ;
			else if ( b[0] == m + 1            ) write( "▀" ) ;
			else if ( b[1] == m                ) write( "▄" ) ;
			else                                 write( "█" ) ;
		}
		writeln() ;
	}
}

// actions

int log( string[] args ) {
	if ( args.length > 1 ) return usage( "log" ) ;
	string arg ;
	if ( args.length == 1 ) arg = args[0] ;
	else {
		write( "How're you doing today? (1-10): " ) ;
		arg = readln.chomp ;
	}
	int val = 0 ;
	try val = arg.to!int ;
	catch (Throwable) { }

	if ( val < 1 || val > 10 ) {
		stderr.writeln( "Expected a number 1-10, not '" , arg , "'" ) ;
		return usage( "log" ) ;
	}

	const string[] comments = [
		"I'd give you a hug if I wasn't an emotionless computer program <3" ,
		"Oh no, hope you feel better soon <3"                               ,
		"Aw I'm sorry :("                                                   ,
		"Aw that's a shame :("                                              ,
		"Just meh? That's ok ^^"                                            ,
		"Not great but not terrible either!"                                ,
		"Valid to feel that way!"                                           ,
		"Doin' pretty good!"                                                ,
		"Glad you're doing ok!"                                             ,
		"Amazing! Have a wonderful day!"
	] ;

	// make a comment
	import std.random ;
	choice( comments[ val == 1 ? 0 : val - 2 .. val == 10 ? 10 : val + 1 ] )
		.writeln ;

	string s = val.text ;

	// if we're here then we're good, so log
	auto history = getHistory() ;
	if ( history.length ) {
		if ( history[ $ - 1 ].date == getToday )
			history[ $ - 1 ].values ~= "," ~ s ;
		else history ~= Entry( getToday , s ) ;
	} else {
		history ~= Entry( getToday , s ) ;
	}
	history.save() ;

	return 0 ;
}

int day( string[] args ) {
	if ( args.length ) return usage( "day" ) ;
	auto history = getHistory ;
	if ( history.length == 0 ) return usage( "nohistory" ) ;
	if ( history[ $ - 1 ].date != getToday ) return usage( "nohistory" ) ;

	// get values
	int[] values = history[ $ - 1 ].values.split( "," ).map!( to!int ).array ;

	writeln( "Here's how your day's looking so far:" ) ;
	graph( values ) ;

	return 0 ;
}

int week( string[] args ) {
	if ( args.length ) return usage( "week" ) ;
	auto history = getHistory ;
	if ( history.length == 0 ) return usage( "nohistory" ) ;

	writeln( "Here's how your week's looking:" ) ;
	auto dow = todayDate.dayOfWeek ;
	writeln( "   " , "SMTWTFSSMTWTFSSM"[ dow + 1 .. dow + 8 ] ) ;

	getDays( 6 ).graph ;

	return 0 ;
}

int month( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
int year( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
int all( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
int edit( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
int help( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
