package TweetConfig;

use strict;
use warnings;
use Config::Simple;

our $printer;
our $search_term;
our $debug            = 0;

our $top_gap          = 3;
our $bottom_gap       = 6;
our $line_gap         = 4;
our $y_gap            = 3;
our $x_gap            = 3;

our $name_font        = 'DejaVuSans-Bold.ttf';
our $name_size        = 16;

our $screen_name_font = 'DejaVuSans.ttf';
our $screen_name_size = 16;

our $text_font        = 'DejaVuSans.ttf';
our $text_size        = 14;

our $time_font        = 'DejaVuSans.ttf';
our $time_size        = 12;

my $config = Config::Simple->new('config.ini');

$printer          = ($config->param('printer') or die("printer is not configured."));
$search_term      = ($config->param('search_term') or die("search_term is not configured."));
$debug            = ($config->param('debug') or $debug);

$top_gap          = ($config->param('top_gap') or $top_gap);
$bottom_gap       = ($config->param('bottom_gap') or $bottom_gap);
$line_gap         = ($config->param('line_gap') or $line_gap);
$y_gap            = ($config->param('y_gap') or $y_gap);
$x_gap            = ($config->param('x_gap') or $x_gap);

$name_font        = ($config->param('name_font') or $name_font);
$name_size        = ($config->param('name_size') or $name_size);

$screen_name_font = ($config->param('screen_name_font') or $screen_name_font);
$screen_name_size = ($config->param('screen_name_size') or $screen_name_size);

$text_font        = ($config->param('text_font') or $text_font);
$text_size        = ($config->param('text_size') or $text_size);

$time_font        = ($config->param('time_font') or $time_font);
$time_size        = ($config->param('time_size') or $time_size);

if ( not $printer =~ m/^\|/ ) {
    $printer = ">" . $printer;
}

if ( $debug > 0 ) {
    print("loaded configuration\n");
}
