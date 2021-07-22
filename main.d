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
import std.range     ;

int usage( string arg0 ) {
	switch ( arg0 ) {
		case "l" , "log"   : writeln( "Usage: log [1-10]"     ) ; break ;
		case "d" , "day"   : writeln( "Usage: day"            ) ; break ;
		case "w" , "week"  : writeln( "Usage: week"           ) ; break ;
		case "m" , "month" : writeln( "Usage: month"          ) ; break ;
		case "y" , "year"  : writeln( "Usage: year"           ) ; break ;
		case "a" , "all"   : writeln( "Usage: all"            ) ; break ;
		case "h" , "help"  : writeln( "Usage: help [command]" ) ; break ;
		case "n" , "note"  :
			writeln( "Usage: note [yyyy-mm-dd] [note]" ) ;
			break ;
		case "e" , "edit"  :
			writeln( "Usage: edit [yyyy-mm-dd] [1-10]" ) ;
			break ;
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

int help( string[] args ) {
	const string logHelp = "log|l [1-10]
\tLog your mood for today from 1-10. You can log multiple times per day.
\tIf you don't provide the value straight away you'll be prompted for it." ;
	const string showHelp = "day|week|month|year|all|d|w|m|y|a
\tDisplay your mood history over the given time period." ;
	const string editHelp = "edit|e [yyyy-mm-dd] [1-10]
\tUpdate your mood score for today or the date given. If you don't provide
\tthe value straight away you'll be prompted for it." ;
	const string noteHelp = "note|n [yyyy-mm-dd] [note]
\tAdd a note for today or the date given. If you don't provide a note
\tyou'll be prompted for it." ;
	const string helpHelp = "help|h [command]
\tShow help for the given command, or all if none is provided." ;

	if ( args.length > 1 ) return usage( "help" ) ;
	if ( args.length == 0 ) {
		writeln(
			"Usage: mood {log|day|week|month|year|all|edit|help|[ldwmyaeh]}\n"
		) ;
		logHelp .writeln ;
		showHelp.writeln ;
		editHelp.writeln ;
		noteHelp.writeln ;
		helpHelp.writeln ;
	} else if ( args.length == 1 ) {
		switch ( args[0] ) {
			case "l" , "log" : logHelp.writeln ; break ;
			case "d" , "w" , "m" , "y" , "a" ,
			     "day" , "week" , "month" , "year" , "all" :
				showHelp.writeln ; break ;
			case "e" , "edit" : editHelp.writeln ; break ;
			case "n" , "note" : noteHelp.writeln ; break ;
			case "h" , "help" : helpHelp.writeln ; break ;
			default : return usage( "help" ) ;
		}
	}
	return 0 ;
}

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
		case "n" , "note"  : return note ( args[2..$] ) ;
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

alias Entry = Tuple!( string , "date" , string , "values" , string , "note" ) ;

Entry[] getHistory() {
	ensureHistoryFile ;
	return historyFile.readText.splitLines.map!( l => l.split( " " ) )
		.map!( a =>
			Entry( a[0] , a[1] , a.length > 2 ? a[2..$].join( " " ) : "" )
		).array ;
}

void save( Entry[] history ) {
	ensureHistoryFile ;
	std.file.write( historyFile ,
		history.map!( e => e.date ~ " " ~ e.values ~ " " ~ e.note )
			.array.join( "\n" )
	) ;
}

string getToday() {
	return Clock.currTime.toLocalTime.toISOExtString[0..10] ;
}

Date todayDate() { return Date.fromISOExtString( getToday ) ; }

alias ValuesEntries = Tuple!( int[] , "values" , Entry[] , "entries" ) ;

ValuesEntries getDays( int daysago ) {
	auto history = getHistory ;
	if ( history.length == 0 ) return ValuesEntries() ;

	auto today    = todayDate               ;
	auto firstDay = today - days( daysago ) ;
	auto entry    = history.length - 1      ;
	int[]   values  ;
	Entry[] entries ;

	while ( today >= firstDay ) {
		if ( entry < 0 || entry >= history.length ) values ~= [ 0 , 0 ] ;
		else if ( history[entry].date == today.toISOExtString ) {
			auto todayValues = history[entry].values.split( "," ).map!( to!int )
				.array ;
			if ( todayValues.length == 1 )
				values ~= [ todayValues[0] , todayValues[0] ] ;
			else values ~= [
				// these are in reverse because the whole thing will be reversed
				// later
				cast(int)( todayValues[ $ / 2 .. $ ].mean ) ,
				cast(int)( todayValues[ 0 .. $ / 2 ].mean )
			] ;
			entry -- ;
		} else values ~= [ 0 , 0 ] ;

		today -= days( 1 ) ;
	}
	return ValuesEntries( values.reverse , history[ entry + 1 .. $ ] ) ;
}

const string[] months = [ "" ,
	"Jan" , "Feb" , "Mar" , "Apr" , "May" , "Jun" ,
	"Jul" , "Aug" , "Sep" , "Oct" , "Nov" , "Dec"
] ;

alias MonthData = Tuple!( short , "year" , string , "month" ,
                          int[] , "values" ) ;
alias MonthsEntries = Tuple!( MonthData[] , "data" , Entry[] , "entries" ) ;
MonthsEntries getMonths( Date from ) {
	auto history = getHistory ;
	if ( history.length == 0 ) return MonthsEntries() ;

	auto   today = todayDate             ;
	ulong  entry = history.length - 1    ;
	string month = months[ today.month ] ;
	int[]       values ;
	MonthData[] data   ;

	while ( today >= from ) {
		if ( entry < 0 || entry >= history.length ) values ~= [ 0 , 0 ] ;
		else if ( history[entry].date == today.toISOExtString ) {
			auto todayValues = history[entry].values.split( "," ).map!( to!int )
				.array ;
			if ( todayValues.length == 1 )
				values ~= [ todayValues[0] , todayValues[0] ] ;
			else values ~= [
				// these are in reverse because the whole thing will be reversed
				// later
				cast(int)( todayValues[ $ / 2 .. $ ].mean ) ,
				cast(int)( todayValues[ 0 .. $ / 2 ].mean )
			] ;
			entry -- ;
		} else values ~= [ 0 , 0 ] ;

		short y = today.year ;
		today -= days( 1 ) ;
		if ( month != months[ today.month ] ) {
			// new month
			data  ~= MonthData( y , month , values.reverse ) ;
			month  = months[ today.month ]                   ;
			values = []                                      ;
			if ( entry < 0 || entry >= history.length ) break ;
		}
	}

	return MonthsEntries( data.reverse , history[ entry + 1 .. $ ] ) ;
}

void graph( int[] values )
in ( std.algorithm.all!( v => v >= 0 && v <= 10 )( values ) ,
     "All values must be 0-10" ) {
	const string[] prefixes = [ ":D" , ":)" , ":|" , ":(" , ":C" ] ;
	const string[] colours = [
		"\x1b[92m" , "\x1b[32;100m" , "\x1b[0m" , "\x1b[31;100m" , "\x1b[91m"
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
			if ( values[ i + 1 ] < bar[0] && values[ i + 1 ] > 0 )
				bar[0] = values[ i + 1 ] + 1 ;
		bars ~= bar ;
	}

	// draw graph
	static foreach ( ulong l , int m ; [ 9 , 7 , 5 , 3 , 1 ] ) {
		write( colours[l] , prefixes[l] , " " ) ;
		foreach ( b ; bars ) {
			// left half
			if      ( b[0] > m + 1 || b[1] < m ) write( " " ) ;
			else if ( b[0] == m + 1            ) write( "▀" ) ;
			else if ( b[1] == m                ) write( "▄" ) ;
			else                                 write( "█" ) ;
		}
		writeln( reset ) ;
	}
}

void heatmap( MonthData[] data ) {
	const string[] blocks = [ " " ,
		"\x1b[91m▁" , "\x1b[91m▂" , "\x1b[31m▃" , "\x1b[31m▄" ,
		"\x1b[30m▄" , "\x1b[30m▅" ,
		"\x1b[32m▅" , "\x1b[32m▆" , "\x1b[92m▇" , "\x1b[92m█"
	] ;

	writeln(
		"     1   3   5   7   9   11  13  15  17  19  21  23  25  27  29  31 "
	) ;
	bool lightBg = false ;
	foreach ( i , m ; data ) {
		if ( lightBg ) write( "\x1b[100m" ) ;
		lightBg = ! lightBg ;
		if ( m.month == "Jan" || i == 0 ) write( m.year , " " ) ;
		else std.stdio.write( m.month , "  " ) ;
		foreach ( v ; 0 .. 62 )
			write( blocks[ m.values.length > v ? m.values[v] : 0 ] ) ;
		//foreach ( v ; m.values ) write( blocks[v] ) ;
		writeln( "\x1b[0m" ) ;
	}
}

void showNotes( Entry[] entries ) {
	foreach ( e ; entries ) if ( e.note.length )
		writeln( "[" , e.date , "]: " , e.note ) ;
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
		else history ~= Entry( getToday , s , "" ) ;
	} else history ~= Entry( getToday , s , "" ) ;
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
	writeln( "   " , ".".repeat( values.length ).join( " " ) ) ;
	values.map!( d => [ d , d ] ).array.join( cast(int[])[] ).graph ;

	if ( history[ $ - 1 ].note.length )
		writeln( "Your note for today: " , history[ $ - 1 ].note ) ;
	else writeln( "No note for today" ) ;

	return 0 ;
}

int week( string[] args ) {
	if ( args.length ) return usage( "week" ) ;
	auto history = getHistory ;
	if ( history.length == 0 ) return usage( "nohistory" ) ;

	writeln( "Here's how your week's looking:" ) ;
	auto dow = todayDate.dayOfWeek ;
	writeln( "   " ,
		"SMTWTFSSMTWTFSSM"[ dow + 1 .. dow + 8 ].map!( d => [d] ).join( "   " )
	) ;

	auto days = getDays( 6 ) ;
	days.values.map!( d => [ d , d ] ).array.join( cast(int[])[] ).graph ;
	auto notes = days.entries.filter!( e => e.note.length ).array ;
	if ( notes.length ) {
		foreach ( e ; notes ) {
			writeln( [
				"Sunday   " , "Monday   " , "Tuesday  " , "Wednesday" ,
				"Thursday " , "Friday   " , "Saturday "
			][ Date.fromISOExtString( e.date ).dayOfWeek ] ,
				": " , e.note ) ;
		}
	} else writeln( "No notes for this week" ) ;

	return 0 ;
}

int month( string[] args ) {
	if ( args.length ) return usage( "month" ) ;
	auto history = getHistory ;
	if ( history.length == 0 ) return usage( "nohistory" ) ;

	writeln( "Here's how your month's looking:" ) ;

	string[] markers           ;
	auto     today = todayDate ;
	bool     labelOnOdd        ;
	foreach ( i ; 0 .. 30 ) {
		auto d = today - days( i ) ;
		if ( d.day == 1 ) {
			markers ~= months[ d.month ] ;
			labelOnOdd = markers.length % 2 ;
		} else markers ~= d.day.text ;
	}
	markers = markers.reverse ;
	markers[0] = months[ ( today - days( 29 ) ).month ] ;
	markers[1] = markers[0]                             ;
	write( "   " ) ;
	foreach ( i ; iota( labelOnOdd ? 1 : 0 , 30 , 2 ) )
		markers[i].leftJustifier( 4 ).write ;
	writeln ;

	auto days = getDays( 29 ) ;
	days.values.graph ;
	days.entries.showNotes ;

	return 0 ;
}

int year( string[] args ) {
	if ( args.length ) return usage( "year" ) ;

	auto from = todayDate.add!"years"( - 1 ) ;
	from.day  = 1 ;
	from = from.add!"months"( 1 ) ;
	auto data = getMonths( from ) ;
	if ( data.data.length == 0 ) return usage( "nohistory" ) ;

	writeln( "Here's how the last year has been:" ) ;
	data.data.heatmap ;
	data.entries.showNotes ;

	return 0 ;
}

int all( string[] args ) {
	if ( args.length ) return usage( "all" ) ;

	auto data = getMonths( Date( 1970 , 1 , 1 ) ) ;
	if ( data.data.length == 0 ) return usage( "nohistory" ) ;

	writeln( "Here's your entire mood history:" ) ;
	data.data.heatmap ;
	data.entries.showNotes ;

	return 0 ;
}

mixin template getDateFn( string helpText ) {
	bool getDate( bool b = true )() {
		if ( date == "" ) {
			date = getToday ;
			return true ;
		}

		try date = Date.fromISOExtString( date ).toISOExtString ;
		catch (Throwable) {
			static if ( b ) {
				stderr.writeln( "Expected date in form 'yyyy-mm-dd', not '" ,
				                date , "'" ) ;
				usage( helpText ) ;
			}
			return false ;
		}
		return true ;
	}
}

int edit( string[] args ) {
	if ( args.length > 2 ) return usage( "edit" ) ;
	string date   ;
	string newval ;

	mixin getDateFn!"edit" ;

	bool getValue( bool b = true )() {
		if ( newval == "" ) {
			write( "What's your new rating? (1-10): " ) ;
			newval = readln.chomp ;
		}

		int val = 0 ;
		try val = newval.to!int ;
		catch (Throwable) { }
		if ( val < 1 || val > 10 ) {
			static if ( b ) {
				stderr.writeln( "Expected a number 1-10, not '" , newval ,
				                "'" ) ;
				usage( "edit" ) ;
			}
			return false ;
		}
		return true ;
	}

	if ( args.length == 2 ) { // date value
		date   = args[0] ;
		newval = args[1] ;
		if ( ! getDate ) return 0 ;
		if ( ! getValue ) return 0 ;
	} else if ( args.length == 1 ) {
		date = args[0] ;
		if ( ! getDate!false ) {
			date   = getToday ;
			newval = args[0]  ;
			if ( ! getValue ) return 0 ;
		}
	}
	getDate!false ;
	if ( ! getValue ) return 0 ;

	// now apply
	auto history = getHistory ;
	auto i = history.countUntil!( e => e.date == date ) ;
	if ( i == -1 ) history = ( history ~ Entry( date , newval , "" ) )
		.sort!( ( a , b ) =>
			Date.fromISOExtString( a.date ) < Date.fromISOExtString( b.date )
		).array ;
	else history[i].values = newval ;
	history.save ;

	writeln( "Entry for '" , date , "' has been updated. Have a nice day!" ) ;

	return 0 ;
}

int note( string[] args ) {
	string date ;
	string note ;

	mixin getDateFn!"note" ;

	if ( args.length ) {
		date = args[0] ;
		if ( getDate!false ) {
			if ( args.length > 1 ) note = args[1..$].join( " " ) ;
		} else {
			date = getToday ;
			note = args.join( " " ) ;
		}
	}
	getDate!false ;
	if ( note == "" ) {
		write( "Comment for the day?: " ) ;
		note = readln.chomp ;
	}

	// and save
	auto history = getHistory ;
	auto i = history.countUntil!( e => e.date == date ) ;
	if ( i == -1 ) writeln( "No data for '" , date ,
		"'. Log a mood value with 'mood log " , date ,
		" [1-10]' before adding a note" ) ;
	else history[i].note = note ;
	history.save ;

	writeln( "Entry for '" , date , "' has been updated. Have a nice day!" ) ;

	return 0 ;
}
