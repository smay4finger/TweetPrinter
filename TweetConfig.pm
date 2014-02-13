package TweetConfig;

use Config::Simple;

our $printer;
our $search_term;
our $debug;

BEGIN {
    my $config = Config::Simple->new('config.ini');

    $printer = $config->param('printer') or die("printer is not configured.");
    $search_term = $config->param('search_term') or die("search_term is not configured.");
    $debug = $config->param('debug') or 0;

    if ( $debug > 0 ) {
        print("loaded configuration\n");
    }
}
