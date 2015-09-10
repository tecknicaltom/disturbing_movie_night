#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use feature 'say';
use Data::Dumper;
use Reddit::Client;
use List::Util qw(shuffle);
use File::Slurp;

$| = 1;
my $num_trials = 20;

my $session = 'reddit-session';
my $reddit = Reddit::Client->new(
	session_file => $session,
	user_agent => 'App/1.0',
);

unless ($reddit->is_logged_in) {
	my $password = read_file('password.txt');
	chomp $password;
	$reddit->login('tecknicaltom', $password);
	$reddit->save_session();
}

say "==========================";
say "  Disturbing Movie Night  ";
say "       Movie Picker       ";
say "==========================";
my $now = localtime();
say "";
say "Running at: $now";
say "";

my %samples;
my %final_scores;

for my $trial (1 .. $num_trials)
{
	say "trial $trial";
	my $links = $reddit->fetch_links(subreddit => '/r/disturbingmovienight', limit => 200);
	foreach (@{$links->{items}}) {
		if (($_->{link_flair_text} // '') ne 'watched')
		{
			$samples{$_->{title}}->{$_->{score}}++;
		}
	}
	sleep 2;
}

foreach my $movie (keys %samples)
{
	my $mode = undef;
	my $max_count = undef;
	my $count = 0;
	foreach my $score (keys %{$samples{$movie}})
	{
		($mode, $max_count) = ($score, $samples{$movie}->{$score}) if(!defined($max_count) || $samples{$movie}->{$score} > $max_count);
		$count += $samples{$movie}->{$score};
	}
	$final_scores{$movie} = $mode;
}

say "";

foreach my $movie (sort { $final_scores{$b} <=> $final_scores{$a} } keys %final_scores)
{
	say $final_scores{$movie} . " " . $movie . "  score breakdown: " .
		(join ", ", map { "${_} pt x $samples{$movie}->{$_}" } sort { $a <=> $b } keys %{$samples{$movie}});
}

my @hat;
foreach my $movie (keys %final_scores)
{
	push @hat, $movie for( 1 .. $final_scores{$movie} );
}

say "";
say "=====================================";
say "Hat pre-shuffle:";
say join "\n", @hat;

@hat = shuffle @hat;

say "";
say "=====================================";
say "Hat post-shuffle:";
say join "\n", @hat;

say "";
say "THE WINNER IS: ",$hat[0];
