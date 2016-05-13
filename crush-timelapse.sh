#!/usr/bin/env perl

use warnings;
use strict;

use File::Basename;
use File::Spec::Functions;
use Getopt::Long;

my $bitrate = '30M'; # set bitrate, as the -qscale parameter doesn't work well
my $speedup = 10;

GetOptions(
    "speedup=i" => \$speedup,
    "bitrate=s" => \$bitrate,
);

my $pts_speedup = 1/$speedup;
my $bitrate_command = ($bitrate ? "-b:v $bitrate" : "-qscale:v 0");
my $bitrate_string  = $bitrate  ? "${bitrate}bps" : "same quality as input";

print "Encoding files at ${speedup}x (${bitrate_string}):\n";
print join("\n", map { ' * ' . $_ } @ARGV), "\n";

for my $file (@ARGV) {
    print "Processing $file...\n";
    my ($filename, $dirs, $extension) = fileparse($file, '\.[^\.]*');
    my $output_file = catfile($dirs, $filename . "-${speedup}x" . $extension);

    qx{ ffmpeg -i $file -filter:v "setpts=$pts_speedup*PTS" $bitrate_command -an $output_file };
}

=pod

=head1 crush-timelapse

Speed a video up using ffmpeg.

This is useful when you shoot a video that's destined to be a timelapse.
Often these are sped up 10x-100x, and keeping the original video takes up an eye-watering amount of space.

This script speeds up the original footage by 10x, which reduces the file size to 1/10th of the original and keeps everything a bit more managable. Crushed files are also less unwieldy when using video editing software.

The speedup factor can be customised.

=head1 Example Usage

=over 1

=item crush-timelapse --speedup 20 IMG_1234.mp4 # speed up a video by a factor of 20

=item crush-timelapse --bitrate 20M IMG_56*.mp4 # speed up all the videos that match the glob IMG_56.mp4, and encode the output at a bitrate of 20Mbps

=back

=head1 Options

=over 1

=item --speedup - speedup factor. Default 10x.

=item --bitrate - bitrate of output in ffmpeg format, eg 20M. Defaults to bitrate of source.

=back

=head1 Output filename

Outputs to $file-${speedup}x.ext

e.g. IMG_1234.mp4 sped up at 10x --> IMG_1234-10x.mp4
