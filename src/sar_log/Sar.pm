package Test::Parser::Sar;

=head1 NAME

Test::Parser::Sar - Perl module to parse output from sar.

=head1 SYNOPSIS

 use Test::Parser::Sar;

 my $parser = new Test::Parser::Sar;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms sar output into a hash that can be used to generate
XML.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;
use XML::Simple;
use File::Basename;

@Test::Parser::Sar::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              time_units
              info
              proc_s
              cpu
              cswch_s
              inode
              intr
              intr_s
              io_tr
              io_bd
              memory
              memory_usage
              net_ok
              net_err
              net_sock
              paging
              queue
              swapping
              rpc_send
              rpc_recv
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::Sar instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::Sar $self = fields::new($class);
    $self->SUPER::new();

    $self->name('sar');
    $self->type('standards');

    #
    # Sar data.
    #
    $self->{info} = '';
    $self->{proc_s} = ();
    $self->{cpu} = ();
    $self->{cswch_s} = ();
    $self->{inode} = ();
    $self->{intr} = ();
    $self->{intr_s} = ();
    $self->{io_tr} = ();
    $self->{io_bd} = ();
    $self->{memory} = ();
    $self->{memory_usage} = ();
    $self->{net_ok} = ();
    $self->{net_err} = ();
    $self->{net_sock} = ();
    $self->{paging} = ();
    $self->{queue} = ();
    $self->{swapping} = ();
    $self->{rpc_send} = ();
    $self->{rpc_recv} = ();

    return $self;
}

=head3 data()

Returns a hash representation of the sar data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {
            sar => {
                    proc_s => $self->{proc_s},
                    cswch_s => $self->{cswch_s},
                    cpu => $self->{cpu},
                    inode => $self->{inode},
                    intr => $self->{intr},
                    intr_s => $self->{intr_s},
                    io => {
                            tr => $self->{io_tr},
                            bd => $self->{io_bd}},
                    memory => $self->{memory},
                    memory_usage => $self->{memory_usage},
                    paging => $self->{paging},
                    network => {
                            ok => $self->{net_ok},
                            err => $self->{net_err},
                            sock => $self->{net_sock}},
                    queue => $self->{queue},
                    swapping => $self->{swapping},
                    rpc => {
                        send =>$self->{rpc_send},
                        recv =>$self->{rpc_recv}}
                    }};
}

=head3

Override of Test::Parser's default parse() routine to make it able
to parse sar output.  Support only reading from a file until a better
parsing algorithm comes along.

=cut
sub parse {
    #
    # TODO
    # Make this handle GLOBS and stuff like the parent class.
    #
    my $self = shift;
    my $input = shift or return undef;
    my ($name, $path) = @_;

    my $retval = 1;

    if (!ref($input) && -f $input) {
        $name ||= basename($input);
        $path ||= dirname($input);

        open (FILE, "< $input")
                or warn "Could not open '$input' for reading:  $!\n"
                and return undef;
        while (<FILE>) {
            chomp($_);
            my @data = split / +/, $_;
            my $count = scalar @data;
            #
            # Capture the interrupts per processor.  sar -I SUM -P ALL
            # This is hard because the number of columns varies depending on the
            # number of interrupt addresses.
            #
            # Let's hope we can always determine this is when the 2nd column
            # starts with CPU and the next column is i000/s, but we'll try to
            # pattern match the beginning 'i' and ending '/s' parts.
            #
            if ($count > 2 and $data[1] eq 'CPU' and $data[2] =~ /^i.*\/s$/) {
                while (my $line = <FILE>) {
                    chomp($line);
                    my @data2 = split / +/, $line;
                    last if (scalar @data2 == 0 or $data2[0] eq 'Average:');
                    defined $self->{intr}->{"cpu:$data2[1]"} or $self->{intr}->{"cpu:$data2[1]"} = [];
                    my $h = {time => $data2[0]};
                    for (my $i = 2; $i < $count; $i++) {
                        $data[$i] =~ /^(i.*)\/s$/;
                        $h->{$1} = $data2[$i];
                    }
                    push @{$self->{intr}{"cpu:$data2[1]"}}, $h;
                }
            } elsif ($count == 2) {
                if ($data[1] eq 'proc/s') {
                    #
                    # Process creation activity.  sar -c
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 2 and $data[0] ne 'Average:') {
                            push @{$self->{proc_s}},
                                    {time => $data[0], proc_s => $data[1]};
                        } else {
                            last;
                        }
                    }
                } elsif ($data[1] eq 'cswch/s') {
                    #
                    # System (context) switching activity.  sar -w
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 2 and $data[0] ne 'Average:') {
                            push @{$self->{cswch_s}},
                                    {time => $data[0], cswch_s => $data[1]};
                        } else {
                            last;
                        }
                    }
                }
            } elsif ($count == 3) {
                if ($data[1] eq 'INTR') {
                    #
                    # Total interrupts.  sar -I SUM
                    # Keep reading until we hit an empty line.
                    #
                    my $time = '';#warning;!!!!!ad_hoc!!!!!
                    my $info = {};
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 3 and $data[0] ne 'Average:') {
                            $data[1] ne 'sum' or next;
                            if($time eq '') {
                                $time = $data[0];
                            } else {
                                $time eq $data[0] or print "intr_s may not right!!!";
                            }
                            $info->{"i$data[1]"} = $data[2];
                        } else {
                            last;
                        }
                    }
                    if($time ne '') {
                        $info->{'time'} = $time;
                        push @{$self->{intr_s}},$info;
                    }
                                    
                } elsif ($data[1] eq 'pswpin/s' and $data[2] eq 'pswpout/s') {
                    #
                    # Swapping statistics.  sar -W
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 3 and $data[0] ne 'Average:') {
                            push @{$self->{swapping}},
                                    {time => $data[0],
                                    pswpin_s => $data[1],
                                    pswpout_s => $data[2]};
                        } else {
                            last;
                        }
                    }
                }
            } elsif ($count == 4) {
                if ($data[1] eq 'frmpg/s') {
                    #
                    # Memory statistics.  sar -R
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 4 and $data[0] ne 'Average:') {
                            push @{$self->{memory}},
                                    {time => $data[0],
                                    frmpg_s => $data[1],
                                    bufpg_s => $data[2],
                                    campg_s => $data[3]};
                        } else {
                            last;
                        }
                    }
                }
            } elsif ($count == 5) {
                if ($data[1] eq 'pgpgin/s') {
                    #
                    # Paging statistics.  sar -B
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 5 and $data[0] ne 'Average:') {
                            push @{$self->{paging}},
                                    {time => $data[0],
                                    pgpgin_s => $data[1],
                                    pgpgout_s => $data[2],
                                    fault_s => $data[3],
                                    majflt_s => $data[4]};
                        } else {
                            last;
                        }
                    }
                }
            } elsif ($count == 6) {
                if ($data[1] eq 'tps') {
                    #
                    # I/O transfer rate statistics.  sar -b
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 6 and $data[0] ne 'Average:') {
                            push @{$self->{io_tr}},
                                    {time => $data[0],
                                    tps => $data[1],
                                    rtps => $data[2],
                                    wtps => $data[3],
                                    bread_s => $data[4],
                                    bwrtn_s => $data[5]};
                        } else {
                            last;
                        }
                    }
                } elsif ($data[1] eq 'totsck') {
                    #
                    # Part of the network statitics, sockets.  sar -n FULL
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 6 and $data[0] ne 'Average:') {
                            push @{$self->{net_sock}},
                                    {time => $data[0],
                                    totsck => $data[1],
                                    tcpsck => $data[2],
                                    udpsck => $data[3],
                                    rawsck => $data[4],
                                    'ip-frag' => $data[5]};
                        } else {
                            last;
                        }
                    }
                } elsif ($data[1] eq 'runq-sz') {
                    #
                    # Queue and load averages.  sar -q
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 6 and $data[0] ne 'Average:') {
                            push @{$self->{queue}},
                                    {time => $data[0],
                                    'runq-sz' => $data[1],
                                    'plist-sz' => $data[2],
                                    'ldavg-1' => $data[3],
                                    'ldavg-5' => $data[4],
                                    'ldavg-15' => $data[5]};
                        } else {
                            last;
                        }
                    }
                }
            } elsif ($count == 7 and $data[1] eq 'call/s') {
                #
                # RPC send
                # Keep reading until we hit an empty line.
                #
                while (my $line = <FILE>) {
                    chomp($line);
                    @data = split / +/, $line;
                    if (scalar @data == 7 and $data[0] ne 'Average:') {
                        push @{$self->{rpc_send}},
                        #00:00:01       call/s retrans/s    read/s   write/s  access/s  getatt/s
                                {time => $data[0],
                                call_s => $data[1],
                                retrans_s => $data[2],
                                read_s => $data[3],
                                write_s => $data[4],
                                access_s => $data[5],
                                getatt_s => $data[6]
                                };
                    } else {
                        last;
                    }
                }
            }
            elsif ($count == 8) {
                if ($data[1] eq 'CPU') {
                    #
                    # CPU utilization report.  sar -u
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 8 and $data[0] ne 'Average:') {
                            defined $self->{cpu}{"cpu:$data[1]"} or $self->{cpu}{"cpu:$data[1]"} = [];
                            push @{$self->{cpu}{"cpu:$data[1]"}},
                                    {time => $data[0],
                                    user => $data[2],
                                    nice => $data[3],
                                    system => $data[4],
                                    iowait => $data[5],
									steal => $data[6],
                                    idle => $data[7]};
                        } else {
                            last;
                        }
                    }
                }
            } elsif ($count == 9) {
                if ($data[1] eq 'IFACE') {
                    #
                    # Part of the network statitics, ok packets.  sar -n FULL
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 9 and $data[0] ne 'Average:') {
                            defined $self->{net_ok}{"iface:$data[1]"} or  $self->{net_ok}{"iface:$data[1]"} = [];
                            push @{$self->{net_ok}{"iface:$data[1]"}},
                                    {time => $data[0],
                                    rxpck_s => $data[2],
                                    txpck_s => $data[3],
                                    rxbyt_s => $data[4],
                                    txbyt_s => $data[5],
                                    rxcmp_s => $data[6],
                                    txcmp_s => $data[7],
                                    rxmcst_s => $data[8]};
                        } else {
                            last;
                        }
                    }
                }
            } elsif ($count == 10) {
                if ($data[1] eq 'DEV') {
                    #
                    # I/O block device statistics.  sar -d
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        #00:00:01          DEV       tps  rd_sec/s  wr_sec/s  avgrq-sz  avgqu-sz     await     svctm     %util
                        if (scalar @data == 10 and $data[0] ne 'Average:') {
                            defined $self->{io_bd}{"dev:$data[1]"} or $self->{io_bd}{"dev:$data[1]"} = [];
                            push @{$self->{io_bd}{"dev:$data[1]"}},
                                    {time => $data[0],
                                    tps => $data[2],
                                    rd_sec_s => $data[3],
                                    wr_sec_s => $data[4],
                                    avgrq_sz => $data[5],
                                    avgqu_sz => $data[6],
                                    await => $data[7],
                                    svctm => $data[8],
                                    util_ratio => $data[9]
                                    };
                        } else {
                            last;
                        }
                    }
                }elsif ($data[1] eq 'kbmemfree') {
                    #
                    # Memory and swap space utilization statistics.  sar -r
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 10 and $data[0] ne 'Average:') {
                            push @{$self->{memory_usage}},
                                    {time => $data[0],
                                    kbmemfree => $data[1],
                                    kbmemused => $data[2],
                                    memused => $data[3],
                                    kbbuffers => $data[4],
                                    kbcached => $data[5],
                                    kbswpfree => $data[6],
                                    kbswpused => $data[7],
                                    swpused => $data[8],
                                    kbswpcad => $data[9]};
                        } else {
                            last;
                        }
                    }
                } elsif ($data[1] eq 'dentunusd') {
                    #
                    # Inode, file and other kernel statistics.  sar -v
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 10 and $data[0] ne 'Average:') {
                            push @{$self->{inode}},
                                    {time => $data[0],
                                    dentunusd => $data[1],
                                    'file-sz' => $data[2],
                                    'inode-sz' => $data[3],
                                    'super-sz' => $data[4],
                                    'psuper-sz' => $data[5],
                                    'dquot-sz' => $data[6],
                                    'pdquot-sz' => $data[7],
                                    'rtsig-sz' => $data[8],
                                    'prtsig-sz' => $data[9]};
                        } else {
                            last;
                        }
                    }
                }
            } elsif ($count == 11) {
                if ($data[1] eq 'IFACE') {
                    #
                    # Part of the network statitics, error packets.  sar -n FULL
                    # Keep reading until we hit an empty line.
                    #
                    while (my $line = <FILE>) {
                        chomp($line);
                        @data = split / +/, $line;
                        if (scalar @data == 11 and $data[0] ne 'Average:') {
                            defined $self->{net_err}{"iface:$data[1]"} or  $self->{net_err}{"iface:$data[1]"} = [];
                            push @{$self->{net_err}{"iface:$data[1]"}},
                                    {time => $data[0],
                                    rxerr_s => $data[2],
                                    txerr_s => $data[3],
                                    coll_s => $data[4],
                                    rxdrop_s => $data[5],
                                    txdrop_s => $data[6],
                                    txcarr_s => $data[7],
                                    rxfram_s => $data[8],
                                    rxfifo_s => $data[9],
                                    txfifo_s => $data[10]};
                        } else {
                            last;
                        }
                    }
                }
            } elsif ($count == 12 and $data[1] eq 'scall/s') {
                #
                # RPC send
                # Keep reading until we hit an empty line.
                #
                while (my $line = <FILE>) {
                    chomp($line);
                    @data = split / +/, $line;
                    if (scalar @data == 12 and $data[0] ne 'Average:') {
                        push @{$self->{rpc_recv}},
                        #00:00:01      scall/s badcall/s  packet/s     udp/s     tcp/s     hit/s    miss/s   sread/s  swrite/s saccess/s sgetatt/s
                        
                                {time => $data[0],
                                scall_s => $data[1],
                                badcall_s => $data[2],
                                packet_s => $data[3],
                                udp_s => $data[4],
                                tcp_s => $data[5],
                                hit_s => $data[6],
                                miss_s => $data[7],
                                sread_s => $data[8],
                                swrite_s => $data[9],
                                saccess_s => $data[10],
                                sgetatt_s => $data[11]
                                };
                    } else {
                        last;
                    }
                }
            }
        }
        close(FILE);
    }
    $self->{name} = $name;
    $self->{path} = $path;

    return $retval;

    return 1;
}

=head3 to_xml()

Returns sar data transformed into XML.

=cut
sub to_xml {
    my $self = shift;
    my $outfile = shift;
    return XMLout({            
            proc_s => {data => $self->{proc_s}},
            cswch_s => {data => $self->{cswch_s}},
            cpu => {data => $self->{cpu}},
            inode => {data => $self->{inode}},
            intr => {data => $self->{intr}},
            intr_s => {data => $self->{intr_s}},
            io => {
                    tr => {data => $self->{io_tr}},
                    bd => {data => $self->{io_bd}}},
            memory => {data => $self->{memory}},
            memory_usage => {data => $self->{memory_usage}},
            paging => {data => $self->{paging}},
            network => {
                    ok => {data => $self->{net_ok}},
                    err => {data => $self->{net_err}},
                    sock => {data => $self->{net_sock}}},
            queue => {data => $self->{queue}},
            swapping => {data => $self->{swapping}} },
            RootName => 'sar');
}

1;
__END__

=head1 AUTHOR

Mark Wong <markwkm@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006-2008 Mark Wong & Open Source Development Labs, Inc.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Parser>

=end

