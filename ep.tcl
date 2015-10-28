##
##	Ep Guides by T-101 / Darklite ^ Primitive
##
##	Fetch previous and upcoming dates of your favorite tv shows
##
##	Usage: !ep show		name can contain spaces
##	Examples: 
##		!ep simpsons
##		!ep x files
##		!ep newsroom_2012	# for when best guess fails
##
##	Also you need to set which channels you want to bot respond.
##	In the eggdrop partyline do: .+chanset #channel +epguides
##
##	Use at own risk, and be nice towards www.epguides.com for
##	such an awesome, free service
##
##	2015 | darklite.org | primitive.be | IRCNet
##
##
## Version history:
##		1.0	-	Initial release


namespace eval ::ep {

set epVersion "v1.0"

setudef flag epguides

bind pub - !ep ::ep::announce

package require http

proc getEpisode { args } {
	set tvShow [join [string tolower [regsub -all {[:\/\s\.@\[\]\\!\"#¤%&=+\?<>,\*€$\{\}\^~\'\`\|;]} $args {}]]]
        set url "http://epguides.com/$tvShow/"
        set userAgent "Chrome 45.0.2454.101"
        ::http::config -useragent $userAgent
        set httpHandler [::http::geturl $url]
        set html [split [::http::data $httpHandler] "\n"]
		set code [::http::code $httpHandler]
        ::http::cleanup $httpHandler

	# if not found, then exit gracefully
	if {[regexp 404 $code]} { return [list "Show \"[join [join $args]]\" not found"] }

	# get show title
	foreach line $html {if {[regexp h1 $line]} { set showName [regsub -all {<([^<])*>} $line {}] }}

	# parse episodedata
	set episodes [regsub -all {<([^<])*>} [regexp -all -inline {<pre>.*pre>} $html] {}]
	foreach episode [join $episodes] {
		set episodeLine [regexp -inline {^[0-9]+\.} [lindex $episode 0]]
		if {[string length $episodeLine]} { lappend cleanEpisodes [regsub -all {\s+} $episode { }] }
	}
	# make a neat little list of all episodes
	foreach episode $cleanEpisodes {
		if {[clock seconds] > [clock scan [lrange $episode 2 4]]} {
			set lastEpisode "([lindex $episode 1]) \"[lrange $episode 5 end]\""
			set lastEpisodeUnixTime [clock scan [lrange $episode 2 4]]
			set lastEpisodeTime "[expr round(([clock seconds] - $lastEpisodeUnixTime) / 60 / 60 / 24.)] days ago"
			set lastEpisodeString "$showName: $lastEpisode $lastEpisodeTime"
		} else {
			set nextEpisode "([lindex $episode 1]) \"[lrange $episode 5 end]\""
			set nextEpisodeUnixTime [clock scan [lrange $episode 2 4]]
			set nextEpisodeTime "in [expr round(($nextEpisodeUnixTime - [clock seconds]) / 60 / 60 / 24.)] days"
			set nextEpisodeString "$showName: $nextEpisode $nextEpisodeTime"
			break }
	}
	# if no dates, gracefully inform of that fact
	if {![info exists lastEpisodeString]} { set lastEpisodeString "$showName: previous episode not known" }
	if {![info exists nextEpisodeString]} { set nextEpisodeString "$showName: next episode not known or series ended" }
	unset -nocomplain html
	return [list "Prev episode - $lastEpisodeString" "Next episode - $nextEpisodeString"]
}

proc announce { nick mask hand channel args } {
	if {[channel get $channel epguides] && [onchan $nick $channel]} {
		if {[llength [lindex $args 0]]} {
			set output [::ep::getEpisode $args]
			foreach item $output { putquick "PRIVMSG $channel :$item" }
		} else { putquick "PRIVMSG $channel :Usage: !ep name. Name can contain spaces" }
	}
}

putlog "Epguides by T-101 $epVersion loaded!"

}
