package TweetSearch;

use strict;
use Net::Twitter;
use Scalar::Util 'blessed';
use Storable;

my $oauth = eval {retrieve("oauth.dat"); } or die("please authenticcate first.");
my $persistent = eval {retrieve("persistent.dat"); };

my $nt = Net::Twitter->new(
    traits => [ 'API::RESTv1_1' ],
    ssl => 1,
    %$oauth,
) or die;


sub search {
    my $search_term = shift or die;
    my @tweets = ();

    eval {
        my $result = $nt->search($search_term, { since_id => ($persistent->{since_id} or 0)});

        $persistent->{since_id} = $result->{search_metadata}->{max_id};
        store($persistent, 'persistent.dat');

        @tweets = sort { $a->{id} cmp $b->{id} } @{$result->{statuses}};
    };
    if ( $@ ) {
        if ( blessed $@ && $@->isa('Net::Twitter::Error') ) {
            warn "Twitter search failed: " . $@->error . "\n";
        }
        else {
            # something bad happened!
            die $@;
        }
    }

    return @tweets;
}
