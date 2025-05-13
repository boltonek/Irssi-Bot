use Irssi;
use Irssi::Irc;
use strict;
use warnings;

use vars qw($VERSION %IRSSI);

$VERSION = "1.0";
%IRSSI = (
    authors     => 'bolton',
    contact     => 'admin@ircnet2.cz',
    name        => 'Irssi bot',
    description => 'command: !op !deop !voice !devoice and more',
    license     => 'BSD License',
    url         => 'https://ircnet2.cz',
    changed     => "04 May 15:00:00 CET 2025",
);

my $admin_file = "$ENV{HOME}/.irssi/bot_admins.txt";
my @admin_hosts = ();
my $keepnick_nick;
my $keepnick_timer;

# === Load admins from file ===
sub load_admins {
    @admin_hosts = ();
    if (open(my $fh, '<', $admin_file)) {
        while (my $line = <$fh>) {
            chomp $line;
            push @admin_hosts, $line if $line =~ /\@/;
        }
        close($fh);
    }
}

# === Save admins to file ===
sub save_admins {
    if (open(my $fh, '>', $admin_file)) {
        foreach my $admin (@admin_hosts) {
            print $fh "$admin\n";
        }
        close($fh);
    }
}

# === Check if user is admin ===
sub is_admin {
    my ($address) = @_;
    return grep { $_ eq $address } @admin_hosts;
}

# === Admin management ===
sub add_admin {
    my ($addr, $server, $chan) = @_;
    if (!grep { $_ eq $addr } @admin_hosts) {
        push @admin_hosts, $addr;
        save_admins();
        $server->command("/msg $chan Admin added: $addr");
    } else {
        $server->command("/msg $chan $addr is already an admin.");
    }
}

sub del_admin {
    my ($addr, $server, $chan) = @_;
    @admin_hosts = grep { $_ ne $addr } @admin_hosts;
    save_admins();
    $server->command("/msg $chan Admin removed: $addr");
}

sub list_admins {
    my ($server, $chan) = @_;
    my $list = join(", ", @admin_hosts);
    $server->command("/msg $chan Current admins: $list");
}

# === IRC commands ===
sub cmd_op {
    my ($server, $channel, $nick) = @_;
    $server->command("MODE $channel +o $nick");
}

sub cmd_ban {
    my ($server, $channel, $nick) = @_;
    $server->command("MODE $channel +b $nick");
}

sub cmd_voice {
    my ($server, $channel, $nick) = @_;
    $server->command("MODE $channel +v $nick");
}

sub cmd_topic {
    my ($server, $channel, $text) = @_;
    $server->command("TOPIC $channel $text");
}

sub cmd_join {
    my ($server, $channel) = @_;
    $server->command("JOIN $channel");
}

sub cmd_part {
    my ($server, $channel) = @_;
    $server->command("PART $channel");
}

sub cmd_say {
    my ($server, $channel, $text) = @_;
    $server->command("MSG $channel $text");
}

sub cmd_uptime {
    my ($server, $chan) = @_;
    my $uptime = `uptime`;
    chomp($uptime);
    $server->command("/msg $chan Uptime: $uptime");
}

sub cmd_version {
    my ($server, $chan) = @_;
    my $version = `lsb_release -d 2>/dev/null`;
    chomp($version);
    if ($version =~ /^Description:\s+(.+)/) {
        $version = $1;
    } else {
        $version = `uname -a`;
        chomp($version);
    }
    $server->command("/msg $chan VPS version: $version");
}

sub cmd_help {
    my ($server, $chan) = @_;
    my @commands = (
        "!op <#channel> <nick>",
        "!ban <#channel> <nick>",
        "!voice <#channel> <nick>",
        "!topic <#channel> <text>",
        "!join <#channel>",
        "!part <#channel>",
        "!say <#channel> <message>",
        "!nick <new_nick>",
        "!uptime",
        "!version",
        "!addadmin <nick\@host>",
        "!deladmin <nick\@host>",
        "!listadmins",
        "!deop <#channel> <nick>",
        "!devoice <#channel> <nick>",
        "!kick <#channel> <nick>",
        "!host <ip_address>"
    );

    my $help_msg = join(" | ", @commands);
    $server->command("/msg $chan Available commands: $help_msg");
}

# === KEEP NICK ===
sub start_keepnick {
    my ($nick, $server, $chan) = @_;
    stop_keepnick();  # Stop first if running

    $keepnick_nick = $nick;
    $keepnick_timer = Irssi::timeout_add(30000, sub {
        return unless defined $keepnick_nick;
        $server->command("/nick $keepnick_nick") if $server->{nick} ne $keepnick_nick;
    }, undef);

    $server->command("/msg $chan Keepnick active for nick: $keepnick_nick");
}

sub stop_keepnick {
    if ($keepnick_timer) {
        Irssi::timeout_remove($keepnick_timer);
        $keepnick_timer = undef;
    }
    $keepnick_nick = undef;
}

# === Command processing ===
sub handle_command {
    my ($msg, $server, $address, $default_chan) = @_;
    return unless is_admin($address);

    if ($msg =~ /^!op (\S+) (\S+)/) {
        cmd_op($server, $1, $2);
    } elsif ($msg =~ /^!ban (\S+) (\S+)/) {
        cmd_ban($server, $1, $2);
    } elsif ($msg =~ /^!voice (\S+) (\S+)/) {
        cmd_voice($server, $1, $2);
    } elsif ($msg =~ /^!topic (\S+) (.+)/) {
        cmd_topic($server, $1, $2);
    } elsif ($msg =~ /^!join (\S+)/) {
        cmd_join($server, $1);
    } elsif ($msg =~ /^!part (\S+)/) {
        cmd_part($server, $1);
    } elsif ($msg =~ /^!say (\S+) (.+)/) {
        cmd_say($server, $1, $2);
    } elsif ($msg =~ /^!uptime(?: (\S+))?/) {
        my $chan = $1 // $default_chan;
        cmd_uptime($server, $chan) if $chan;
    } elsif ($msg =~ /^!version(?: (\S+))?/) {
        my $chan = $1 // $default_chan;
        cmd_version($server, $chan) if $chan;
    } elsif ($msg =~ /^!addadmin (\S+)/) {
        add_admin($1, $server, $default_chan);
    } elsif ($msg =~ /^!deladmin (\S+)/) {
        del_admin($1, $server, $default_chan);
    } elsif ($msg =~ /^!listadmins/) {
        list_admins($server, $default_chan);
    } elsif ($msg =~ /^!deop (\S+) (\S+)/) {
        cmd_deop($server, $1, $2);
    } elsif ($msg =~ /^!devoice (\S+) (\S+)/) {
        cmd_devoice($server, $1, $2);
    } elsif ($msg =~ /^!kick (\S+) (\S+)/) {
        cmd_kick($server, $1, $2);
    } elsif ($msg =~ /^!host (\S+)/) {
        cmd_host($server, $1, $default_chan);
    } elsif ($msg =~ /^!help$/) {
        cmd_help($server, $default_chan);
    } elsif ($msg =~ /^!nick (\S+)/) {
        cmd_nick($server, $1, $default_chan);
    } elsif ($msg =~ /^!keepnick (\S+)/) {
        start_keepnick($1, $server, $default_chan);
    } elsif ($msg =~ /^!stopkeepnick/) {
        stop_keepnick();
        $server->command("/msg $default_chan Keepnick disabled.");
    }
}

# === Command functions ===
sub cmd_deop {
    my ($server, $channel, $nick) = @_;
    $server->command("MODE $channel -o $nick");
}

sub cmd_devoice {
    my ($server, $channel, $nick) = @_;
    $server->command("MODE $channel -v $nick");
}

sub cmd_kick {
    my ($server, $channel, $nick) = @_;
    $server->command("KICK $channel $nick");
}

sub cmd_host {
    my ($server, $ip, $chan) = @_;
    my $result = `host $ip`;  # Run host lookup
    chomp($result);
    $server->command("/msg $chan Host result: $result");
}

# === Handle public/private messages ===
sub on_public {
    my ($server, $msg, $nick, $address, $target) = @_;
    handle_command($msg, $server, $address, $target);
}

sub on_private {
    my ($server, $msg, $nick, $address) = @_;
    handle_command($msg, $server, $address, $nick);
}

sub cmd_nick {
    my ($server, $newnick, $chan) = @_;
    if ($newnick =~ /^[a-zA-Z0-9_\-\[\]\\\^\{\}\|`]+$/) {
        $server->command("/nick $newnick");
        $server->command("/msg $chan Nick changed to: $newnick");
    } else {
        $server->command("/msg $chan Invalid nick: $newnick");
    }
}

# === Signal registration ===
Irssi::signal_add('message public', 'on_public');
Irssi::signal_add('message private', 'on_private');

# === Initialization ===
load_admins();
Irssi::print("Bot script loaded – !help and more.");
