package TweetImage;

use strict;
use Image::Magick;
use POSIX qw(floor ceil);
use LWP::Simple;

my $width      = 480;
my $top_gap    = 2;
my $bottom_gap = 0;
my $line_gap   = 5;
my $y_gap      = 3;
my $x_gap      = 3;

my $name_font        = { font => 'DejaVuSans-Bold.ttf', pointsize => 16, antialias => 'false' };
my $screen_name_font = { font => 'DejaVuSans.ttf',      pointsize => 16, antialias => 'false' };
my $text_font        = { font => 'DejaVuSans.ttf',      pointsize => 14, antialias => 'false' };


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
    my $name = Image::Magick->new(%$name_font);
    $name->Read('label:' . $tweet->{user}->{name});

    my $screen_name = Image::Magick->new(%$screen_name_font);
    $screen_name->Read('label:\@' . $tweet->{user}->{screen_name});

    my $text_width = $width - $profile_image->Get('width') - 2 * $x_gap;
    my $text = Image::Magick->new(size => sprintf('%d', $text_width), %$text_font);
    $tweet->{text} =~ s/@/\\@/g; # @ must be sanitized, otherwise  evaluated by PerlMagick
    $text->Read('caption:' . $tweet->{text});

    #
    # compose image
    #
    my $profile_image_x1 = 0;
    my $profile_image_y1 = $top_gap;
    my $profile_image_x2 = $profile_image_x1 + $profile_image->Get('width');
    my $profile_image_y2 = $profile_image_y1 + $profile_image->Get('height');

    my $name_x1 = $profile_image_x2 + $x_gap;
    my $name_y1 = $top_gap;
    my $name_x2 = $name_x1 + $name->Get('width');
    my $name_y2 = $name_y1 + $name->Get('height');

    my $screen_name_x1 = $name_x2 + $x_gap;
    my $screen_name_y1 = $top_gap;
    #my $screen_name_x2 = $screen_name_x1 + $screen_name->Get('width');
    #my $screen_name_y2 = $screen_name_y1 + $screen_name->Get('height');

    my $text_x1 = $profile_image_x2 + $x_gap;
    my $text_y1 = $name_y2 + $y_gap;
    my $text_x2 = $text_x1 + $text->Get('width');
    my $text_y2 = $text_y1 + $text->Get('height');

    my $height = $text_y2 + $bottom_gap;
    if ( $height < ($profile_image_y2 + $line_gap + $bottom_gap) ) {
        $height = $profile_image_y2 + $line_gap + $bottom_gap;
    }
    $height = ceil($height / 8) * 8;

    my $line_y = $height - $line_gap;

    my $image = Image::Magick->new(size => sprintf('%dx%d', $width, $height));
    $image->Read('canvas:white');
    $image->Composite(image => $profile_image, geometry => sprintf('%+d%+d', $profile_image_x1, $profile_image_y1));
    $image->Composite(image => $name,          geometry => sprintf('%+d%+d', $name_x1, $name_y1));
    $image->Composite(image => $screen_name,   geometry => sprintf('%+d%+d', $screen_name_x1, $screen_name_y1));
    $image->Composite(image => $text,          geometry => sprintf('%+d%+d', $text_x1, $text_y1));
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

