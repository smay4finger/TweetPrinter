package TweetImage;

use strict;
use warnings;
use Image::Magick;
use POSIX qw(floor ceil);
use LWP::Simple;
use Date::Parse;

use TweetConfig;

if ( $TweetConfig::debug > 0 ) {
    print("initialize image creator\n");
}

my $width      = 576;

sub create {
    my $tweet = shift or die;

    #
    # get profile image from twitter
    #
    my $profile_imageblob = get($tweet->{user}->{profile_image_url}) or warn("$!");
    my $profile_image = Image::Magick->new();
    $profile_image->BlobToImage($profile_imageblob);

    #
    # convert profile image to monochrome
    #
    my $gray50 = Image::Magick->new;
    $gray50->Read('pattern:gray50');
    $profile_image->Remap( image => $gray50 );
    undef $gray50;

    #
    # create text
    #
    if ( $tweet->{user}->{name} eq '' ) {
        $tweet->{user}->{name} = $tweet->{user}->{screen_name};
    }
    my $name = Image::Magick->new(font => $TweetConfig::name_font, 
            pointsize => $TweetConfig::name_size, antialias => 'false');
    $name->Read('label:' . $tweet->{user}->{name});

    my $screen_name = Image::Magick->new(font => $TweetConfig::screen_name_font, 
            pointsize => $TweetConfig::screen_name_size, antialias => 'false');
    $screen_name->Read('label:\@' . $tweet->{user}->{screen_name});

    my $text_width = $width - $profile_image->Get('width') - $TweetConfig::x_gap;
    my $text = Image::Magick->new(size => sprintf('%d', $text_width), 
            font => $TweetConfig::text_font,
            pointsize => $TweetConfig::text_size, antialias => 'false' );
    $tweet->{text} =~ s/@/\\@/g; # @ must be sanitized, otherwise  evaluated by PerlMagick
    $text->Read('caption:' . $tweet->{text});

    my ($ss,$mm,$hh,$day,$month,$year,$zone) = localtime(str2time($tweet->{created_at}, "Europe/Berlin"));
    my $time = Image::Magick->new(font => $TweetConfig::time_font, 
            pointsize => $TweetConfig::time_size, antialias => 'false');
    $time->Read(sprintf('label:%02d:%02d', $hh, $mm));

    #
    # compose image
    #
    my $profile_image_x1 = 0;
    my $profile_image_y1 = 0;
    my $profile_image_x2 = $profile_image_x1 + $profile_image->Get('width');
    my $profile_image_y2 = $profile_image_y1 + $profile_image->Get('height');

    my $name_x1 = $profile_image_x2 + $TweetConfig::x_gap;
    my $name_y1 = $TweetConfig::top_gap;
    my $name_x2 = $name_x1 + $name->Get('width');
    my $name_y2 = $name_y1 + $name->Get('height');

    my $screen_name_x1 = $name_x2 + $TweetConfig::x_gap;
    my $screen_name_y1 = $TweetConfig::top_gap;
    #my $screen_name_x2 = $screen_name_x1 + $screen_name->Get('width');
    #my $screen_name_y2 = $screen_name_y1 + $screen_name->Get('height');

    my $text_x1 = $profile_image_x2 + $TweetConfig::x_gap;
    my $text_y1 = $name_y2 + $TweetConfig::y_gap;
    my $text_x2 = $text_x1 + $text->Get('width');
    my $text_y2 = $text_y1 + $text->Get('height');

    my $height = $text_y2 + $TweetConfig::line_gap + $TweetConfig::bottom_gap;
    if ( $height < ($profile_image_y2 + $TweetConfig::line_gap + $TweetConfig::bottom_gap) ) {
        $height = $profile_image_y2 + $TweetConfig::line_gap + $TweetConfig::bottom_gap;
    }
    $height = ceil($height / 8) * 8;

    my $line_y = $text_y2 + $TweetConfig::line_gap;

    my $image = Image::Magick->new(size => sprintf('%dx%d', $width, $height));
    $image->Read('canvas:white');
    $image->Composite(image => $profile_image, geometry => sprintf('%+d%+d', $profile_image_x1, $profile_image_y1));
    $image->Composite(image => $name,          geometry => sprintf('%+d%+d', $name_x1, $name_y1));
    $image->Composite(image => $screen_name,   geometry => sprintf('%+d%+d', $screen_name_x1, $screen_name_y1));
    $image->Composite(image => $text,          geometry => sprintf('%+d%+d', $text_x1, $text_y1));
    $image->Composite(image => $time,          geometry => sprintf('%+d%+d', $TweetConfig::top_gap, $TweetConfig::y_gap), gravity => "NorthEast");
    $image->Draw(primitive => 'line', points => sprintf('%d,%d %d,%d', 0, $line_y, $width, $line_y));
    $image->Draw(primitive => 'rectangle', 
        points => sprintf('%d,%d %d,%d', $profile_image_x1, $profile_image_y1, $profile_image_x2, $profile_image_y2), 
        fill => 'none', stroke => 1);
    $image->Set(monochrome => 'true');
    $image->Negate();

    undef $profile_image;
    undef $name;
    undef $screen_name;
    undef $text;

    return $image;
}

