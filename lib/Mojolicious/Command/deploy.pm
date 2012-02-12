package Mojolicious::Command::deploy;
use Mojo::Base 'Mojo::Command';

use File::Basename 'basename';
use Getopt::Long qw/GetOptions :config no_auto_abbrev no_ignore_case/;
use lib '~/Projects/Net-Heroku/lib';
use Net::Heroku;
use Git::Repository;
use Data::Dumper;
use Devel::Dwarn;
use Mojo::UserAgent;
use Mojo::IOLoop;
use File::Spec;

has tmpdir => sub { $ENV{MOJO_TMPDIR} || File::Spec->tmpdir };
has ua => sub { Mojo::UserAgent->new->ioloop(Mojo::IOLoop->singleton) };
has description => "Deploy Mojolicious app.\n";
has usage       => <<"EOF";
usage: $0 deploy [OPTIONS]

  mojo deploy heroku

These options are available:
  -a, --api_key <api_key>   Heroku API key (read from ~/.heroku/credentials by default).
EOF

sub run {
  my $self  = shift;
  my $class = $ENV{MOJO_APP};

  #my $path  = $self->class_to_path($class);
  my $script_name = $self->class_to_file($class);

  # Push to heroku app
  #$r->

  # Options
  local @ARGV = @_;
  my $api_key = '';
  GetOptions('a|api_key=s' => sub { $api_key = $_[1] });

  #die $self->usage unless $file;

  print "Creating Heroku app...";
  my $h = Net::Heroku->new(api_key => $api_key);
  my $res = Dwarn $h->create;
  DwarnN $h->add_config(
    name          => $res->{name},
    BUILDPACK_URL => 'http://github.com/judofyr/perloku.git'
  );
  print '...';

  #$h->add_key(key => 'ssh-dss AAAAB3NzaC1kc3MAAACBAONzl+UOQhOFZBw6vIuoDKTOzUeGPJVK+yYlVTco0HbF/YwpIQ4TewrAQoTcZ9Q3bdIMN1ZBBpc4tAYDsAUiuDdhciyZ4E8O30fjAWDRzf7hhv/T9Lmtt8ttzI0vpuPslqdfHLgUTY+FKEQfgF4I/PsWb1P2HQOOhQnid/HoKWcXAAAAFQClEvS8P/iqVabeB/NL4TzUsvyPswAAAIBnc1aLB/zqkmhQpWFbUqh6v9xSnkqcTazA/E1Bhjzppq96SuZ4mNvuN3ZGsVj8Bfz/ZvWPUonBFqU8/lAJXjvIc8tN3EvbGQkks03s/Iav4OWN6hovfOLwqEK7yfeo73bTEkZ0BjqGlGuCeQrIJle4Fz4MHPCaNtsWQ3BBeCIJ/AAAAIEAtBm6wHK9EJnmNFec1eqGW3E/1/WDZ76xgBO07PKodponbn+o50LB6obOyMpJ92pvbZLOoVooSXZnRln6VqbUtE4yJoBk2gb4HVhF40MCYg7ed2sFoH2ofoFfpYXl++TeUv2KuKeWhUzVj9rnKbcn5lvNTlpoFfPoarwlrdJsp4s= glen@Glen-Hinkles-MacBook-Pro.local');

  say "$res->{name}";

  # Home dir
  $self->ua->app($class);
  my $home_dir = Dwarn $self->ua->app->home->to_string;
  my $r        = $self->create_repo($home_dir);

  # Add files to repo
  $r->run(add => Dwarn @{$self->app->home->list_files});
  $r->run(commit => '-m' => 'Initial Commit');

  # Add remote
  $r->run(remote => add => heroku => $res->{git_url});

  # Push app to heroku
  $r->run(push => heroku => 'master');

  # Error
  #unless ($tx->success) {
  #  my $code = $tx->res->code || '';
  #  my $message = $tx->error;
  #  if    ($code eq '401') { $message = 'Wrong username or password.' }
  #  elsif ($code eq '409') { $message = 'File already exists on CPAN.' }
  #  die qq/Problem uploading file "$file". ($message)\n/;
  #}
  say 'Upload sucessful!';
}

sub create_repo {
  my $self     = shift;
  my $home_dir = shift;

  my $git_dir = Dwarn $self->tmpdir . '/mojo_deploy_git_' . int rand 1000;

  Git::Repository->run(init => $git_dir);
  return Git::Repository->new(
    work_tree => $home_dir,
    git_dir   => $git_dir . '/.git'
  );
}

sub is_repo {
  return eval { Git::Repository->new(git_dir => pop . '/.git') };
}

1;

=head1 NAME

Mojolicious::Command::cpanify - Cpanify command

=head1 SYNOPSIS

  use Mojolicious::Command::cpanify;

  my $cpanify = Mojolicious::Command::cpanify->new;
  $cpanify->run(@ARGV);

=head1 DESCRIPTION

L<Mojolicious::Command::cpanify> is a CPAN uploader. Note that this module is
EXPERIMENTAL and might change without warning!

=head1 ATTRIBUTES

L<Mojolicious::Command::cpanify> inherits all attributes from
L<Mojo::Command> and implements the following new ones.

=head2 C<description>

  my $description = $cpanify->description;
  $cpanify        = $cpanify->description('Foo!');

Short description of this command, used for the command list.

=head2 C<usage>

  my $usage = $cpanify->usage;
  $cpanify  = $cpanify->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::cpanify> inherits all methods from L<Mojo::Command>
and implements the following new ones.

=head2 C<run>

  $cpanify->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
