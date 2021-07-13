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

int usage( string arg0 ) {
	switch ( arg0 ) {
		case "log"   : writeln( "Usage: " , helpLog ) ; break ;
		case "day"   : writeln( "Usage: " , helpLog ) ; break ;
		case "week"  : writeln( "Usage: " , helpLog ) ; break ;
		case "month" : writeln( "Usage: " , helpLog ) ; break ;
		case "year"  : writeln( "Usage: " , helpLog ) ; break ;
		case "all"   : writeln( "Usage: " , helpLog ) ; break ;
		case "edit"  : writeln( "Usage: " , helpLog ) ; break ;
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
static string helpLog = "log [1-10]" ;

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
	import std.datetime ;
	return Clock.currTime().toLocalTime.toISOExtString[0..10] ;
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

int day( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
int week( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
int month( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
int year( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
int all( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
int edit( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
int help( string[] args ) { abort( "NOT YET IMPLEMENTED" ) ; return 0 ; }
