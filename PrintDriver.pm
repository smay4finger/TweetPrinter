package PrintDriver;

use strict;
use warnings;
use IO::Handle;
use Image::Magick;

use TweetConfig;

if ( $TweetConfig::debug > 0 ) {
    print("initialize printer at $TweetConfig::printer\n");
}

my $printer;
open($printer, ">", $TweetConfig::printer)
    or die("couldn't open printer: $!; aborting");
binmode($printer);
$printer->autoflush(1);
print($printer "\007"); # cancel
print($printer "\007"); # cancel

sub print {
    my $image = shift or die;

    print($printer "\030"); # cancel
    print($printer "\0331"); # ESC 1 - 7/72in line feeding
    for ( my $y = 0; $y < $image->Get('height'); $y += 8 ) {
        print($printer "\033K" . pack("v", $image->Get('width')));
        for ( my $x = 0; $x < $image->Get('width'); $x++ ) {
            my @pixelz = $image->GetPixels(geometry => "1x8", x => $x, y=> $y, map => 'I', normalize => 'true');
            print($printer pack("B*", join('', @pixelz)));
        }
        print($printer "\012");
    }
}
