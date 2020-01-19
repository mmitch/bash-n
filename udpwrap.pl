#!/usr/bin/env perl
use strict;
use warnings;

# udpwrap.pl - UDP wrapper for bash-n-client
#
# Copyright (C) 2020  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v3 or later.
#
# This file is part of bash-n.
#
# bash-n is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# bash-n is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with bash-n.  If not, see <http://www.gnu.org/licenses/>.

#
# Use this script to connect any of the bash-n bots with the game server.
#
# usage:
#   udpwrap.pl <local_port> <server:port> <bot_script>
#
# example:
#   udpwrap.pl 5000 localhost:4446 ./bash-n-simplebot
#

use IO::Socket::INET;
use IO::Select;
use IPC::Open2;

sub debug(@)
{
    return; # no logging
    
    my ($format, @params) = @_;
    printf STDERR "$format\n", @_;
}

sub parse_commandline_parameters()
{
    my $local_port = shift @ARGV;
    die "no local port given" unless defined $local_port and $local_port;
    
    my $server_addr = shift @ARGV;
    die "no server address given" unless defined $server_addr and $server_addr;
    
    my $bot_cmd = shift @ARGV;
    die "no bot command given" unless defined $bot_cmd and $bot_cmd;

    return ($local_port, $server_addr, $bot_cmd);
}

sub open_listening_udp_port($)
{
    my ($local_port) = @_;

    my $recv = new IO::Socket::INET( Proto => 'udp', LocalPort => $local_port, ReusePort => 1 );
    die "error creating listening socket: $!\n" unless $recv;
    
    debug "listening on port %d", $recv->sockport();

    return $recv;
}

sub open_udp_connection_to_server($$)
{
    my ($local_port, $server_addr) = @_;

    my $send = new IO::Socket::INET( Proto => 'udp', PeerAddr => $server_addr, ReusePort => 1, LocalPort => $local_port )
	or die "error creating sending socket: $!\n";

    return $send;
}

sub start_bot($)
{
    my ($bot_cmd) = @_;

    my ($bot_in, $bot_out);
    my $bot_pid = open2($bot_out, $bot_in, $bot_cmd);
    
    return ($bot_in, $bot_out);
}

sub create_select_list(@)
{
    my $select_list = new IO::Select;
    $select_list->add($_) foreach @_;
    return $select_list;
}

sub wait_for_filehandles_with_input($)
{
    my ($input_filehandles) = @_;
    my @status = IO::Select->select($input_filehandles, undef, undef);
    die "error during select(): $!\n" unless @status;

    return map { $_ => 1 } @{$status[0]};
}

sub copy_data_from_udp_to_bot($$)
{
    my ($udp_in, $bot_in) = @_;
    my $received_data;
    
    $udp_in->recv($received_data, 4096);
    debug " <<< %s", $received_data;
    print $bot_in "$received_data\n";
}

sub copy_data_from_bot_to_udp($$)
{
    my ($bot_out, $udp_out) = @_;
    
    my $line = <$bot_out>;
    chomp $line;
    debug " >>> %s", $line;
    $udp_out->send($line);
}

my ($local_port, $server_addr, $bot_cmd) = parse_commandline_parameters;

my $udp_in = open_listening_udp_port ($local_port);

my $udp_out = open_udp_connection_to_server $local_port, $server_addr;

my ($bot_in, $bot_out) = start_bot $bot_cmd;

my $input_filehandles = create_select_list $udp_in, $bot_out;

while (my %ready_to_read = wait_for_filehandles_with_input $input_filehandles) {
    copy_data_from_udp_to_bot $udp_in,  $bot_in  if exists $ready_to_read{$udp_in};
    copy_data_from_bot_to_udp $bot_out, $udp_out if exists $ready_to_read{$bot_out};
}
