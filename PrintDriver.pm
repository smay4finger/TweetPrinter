package PrintDriver;

use strict;
use warnings;
use IO::Handle;
use Image::Magick;

use TweetConfig;

if ( $TweetConfig::debug > 0 ) {
    print("initialize printer at $TweetConfig::printer\n");
}

sub print {
    my $image = shift or die;

    open(PRINTER, $TweetConfig::printer)
        or die("couldn't open printer: $!; aborting");
    binmode(PRINTER);

    print(PRINTER "\030"); # cancel
    print(PRINTER "\0331"); # ESC 1 - 7/72in line feeding
    for ( my $y = 0; $y < $image->Get('height'); $y += 8 ) {
        print(PRINTER "\033K" . pack("v", $image->Get('width')));
        for ( my $x = 0; $x < $image->Get('width'); $x++ ) {
            my @pixelz = $image->GetPixels(geometry => "1x8", x => $x, y=> $y, map => 'I', normalize => 'true');
            print(PRINTER pack("B*", join('', @pixelz)));
        }
        print(PRINTER "\012");
    }
    close(PRINTER);
}
