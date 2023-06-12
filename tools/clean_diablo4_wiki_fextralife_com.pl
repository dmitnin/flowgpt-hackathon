#!/usr/bin/perl

use strict;
use warnings;

use File::Find;
use FindBin;
use Mojo::DOM;

use constant SCRIPT_DIR_PATH => $FindBin::Bin;
use constant DIRECTORY_PATH => SCRIPT_DIR_PATH . '/tmp/diablo4.wiki.fextralife.com';

# wget --recursive --no-parent https://diablo4.wiki.fextralife.com/Diablo+4+Wiki

my $html_file_count          = 0;
my $html_file_old_total_size = 0;
my $html_file_new_total_size = 0;

my @files;
find(
    sub {
        my $file_path = $File::Find::name;
        return unless -f $file_path;

        push @files, $file_path;
    },
    DIRECTORY_PATH
);

@files = sort @files;

for (my $i = 0; $i < @files; ++$i) {
    my $file_path = $files[$i];

    my $progress = 100.0 * ($i + 1) / scalar(@files);
    printf "(%d/%d - %0.1f%%) %s\n", $i + 1, scalar(@files), $progress, $file_path;

    process_file($file_path);
}

printf "HTML file count:          %d\n", $html_file_count;
printf "HTML file old total size: %s\n", commify($html_file_old_total_size);
printf "HTML file new total size: %s\n", commify($html_file_new_total_size);


sub process_file {
    my $file_path = shift;

    my $file_first_1k = read_file_first_1k($file_path);
    if ($file_first_1k =~ m{<html}) {
        process_html($file_path);
    }
    else {
        process_non_html($file_path);
    }
}

sub read_file_first_1k {
    my $file_path = shift;
    my $LIMIT = 1024;

    my $data;

    open(my $fh, "<", $file_path) or die "Could not open file '$file_path': $!";
    read($fh, $data, $LIMIT) or die "Could not read from file '$file_path': $!";
    close($fh);

    return $data;
}

sub process_html {
    my $file_path = shift;

    $html_file_count += 1;
    $html_file_old_total_size += -s $file_path;

    my $file_content = sub {
        open my $fh, "<$file_path" or die "Could not open file '$file_path': $1";
        local $/ = undef;
        my $content = <$fh>;
        close $fh;
        return $content;
    }->();

    my $remove_all = sub {
        my ($element, $selector) = @_;

        foreach ($element->find($selector)->each()) {
            $_->remove();
        }
    };

    my $dom = Mojo::DOM->new($file_content);

    my $head_title = $dom->find('head>title')->first();
    my $head_description = $dom->find('meta[name="description"]')->first();

    die unless defined $head_title;
    # die unless defined $head_description;

    my $main_contents = $dom->find('div#main-content');
    my $main_contents_count = scalar($main_contents->each());
    if ($main_contents_count == 0) {
        unlink $file_path or die "Could not delete file '$file_path': $!";
        return;
    }

    die if $main_contents_count != 1;

    my $main_content = $main_contents->first();

    $remove_all->($main_content, 'div#discussions-section');
    $remove_all->($main_content, 'div#preview-container');
    $remove_all->($main_content, 'div.table-responsive');
    $remove_all->($main_content, 'div.page-segment-btns');
    $remove_all->($main_content, 'div.clearfix');
    $remove_all->($main_content, 'div#breadcrumbs-bcontainer');
    $remove_all->($main_content, 'form#form-buttons');

    # my $text = $dom->all_text;

    my $new_file_content = sprintf(
        "<html>\n" .
            "<head>\n" .
                "%s\n" .
                "%s\n" .
            "</head>" .
            "<body>" .
                "%s\n" .
            "</body>" .
        "</html>",
        $head_title->to_string(),
        (defined $head_description ? $head_description->to_string() : ''),
        $main_content->to_string(),
    );

    open my $fh, ">$file_path" or die "Could not open file '$file_path' for writing: $!";
    print $fh $new_file_content;
    close $fh;

    $html_file_new_total_size += -s $file_path;
}

sub is_known_non_html {
    my $file_path = shift;

    return 1 if $file_path =~ m{\.(?:jpg|jpeg|png)(?:\?v=[0-9]+)?$};
    return 1 if $file_path =~ m{\/robots\.txt$};
    return 1 if $file_path =~ m{\.css\?js=\w+$};

    return 0;
}

sub process_non_html {
    my $file_path = shift;

    unless (is_known_non_html($file_path)) {
        die "Dunno what to do with '$file_path'";
    }

    unlink $file_path or die "Could not delete file '$file_path': $!";
}

sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1'/g;
    return scalar reverse $text;
}
