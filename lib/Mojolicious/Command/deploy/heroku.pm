package Mojolicious::Command::deploy::heroku;
use Mojo::Base 'Mojo::Command';

use File::Basename 'basename';
use Getopt::Long qw/GetOptions :config no_auto_abbrev no_ignore_case/;
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
has ['opt'];
has usage       => <<"EOF";
usage: $0 deploy heroku [OPTIONS]

  # Create new app with randomly selected name and deploy
  $0 deploy heroku -c

  # Create new app with specified name and deploy
  $0 deploy heroku -c -n happy-cloud-1234

  # Deploy to existing app
  $0 deploy heroku -n happy-cloud-1234

These options are available:
  -n, --appname <name>      Specify app for deployment
  -a, --api-key <api_key>   Heroku API key (read from ~/.heroku/credentials by default).
  -c, --create              Create a new Heroku app
  -v, --verbose             Verbose output (heroku response, git output)
  -h, --help                This message
EOF

sub opt_spec {
  my $self = shift;
  my $opt  = {};

  local @ARGV = @_;
  GetOptions(
    "n|appname" => sub { $opt->{name}    = $_[1] },
    "a|api-key" => sub { $opt->{api_key} = $_[1] },
    "c|create"  => sub { $opt->{create}  = $_[1] },
    "v|verbose" => sub { $opt->{verbose} = $_[1] },
    "h|help"    => sub { $opt->{help}    = $_[1] },
  );

  return $opt;
}

sub validate {
  my $self = shift;
  my $opt  = shift;

  return "\nError: App name required\n" if !defined $opt->{create} and !defined $opt->{name};
}

sub run {
    my $self  = shift;
    my $class = $ENV{MOJO_APP};

    my $path        = $self->class_to_path($class);
    my $script_name = $self->class_to_file($class);

    # Push to heroku app

    # Options
    my $opt = $self->opt_spec(@_);

    # Validate
    die $self->usage if $self->validate($opt);

    print "Creating Heroku app...";
    my $h = Net::Heroku->new(api_key => $opt->{api_key});
    my $res = $h->create;
    do { sleep 1 } while (!$h->app_created(name => $res->{name}));

    $h->add_config(
      name          => $res->{name},
      BUILDPACK_URL => 'http://github.com/tempire/perloku.git',
    );
    print '...';

#$h->add_key(key => 'ssh-dss AAAAB3NzaC1kc3MAAACBAONzl+UOQhOFZBw6vIuoDKTOzUeGPJVK+yYlVTco0HbF/YwpIQ4TewrAQoTcZ9Q3bdIMN1ZBBpc4tAYDsAUiuDdhciyZ4E8O30fjAWDRzf7hhv/T9Lmtt8ttzI0vpuPslqdfHLgUTY+FKEQfgF4I/PsWb1P2HQOOhQnid/HoKWcXAAAAFQClEvS8P/iqVabeB/NL4TzUsvyPswAAAIBnc1aLB/zqkmhQpWFbUqh6v9xSnkqcTazA/E1Bhjzppq96SuZ4mNvuN3ZGsVj8Bfz/ZvWPUonBFqU8/lAJXjvIc8tN3EvbGQkks03s/Iav4OWN6hovfOLwqEK7yfeo73bTEkZ0BjqGlGuCeQrIJle4Fz4MHPCaNtsWQ3BBeCIJ/AAAAIEAtBm6wHK9EJnmNFec1eqGW3E/1/WDZ76xgBO07PKodponbn+o50LB6obOyMpJ92pvbZLOoVooSXZnRln6VqbUtE4yJoBk2gb4HVhF40MCYg7ed2sFoH2ofoFfpYXl++TeUv2KuKeWhUzVj9rnKbcn5lvNTlpoFfPoarwlrdJsp4s= glen@Glen-Hinkles-MacBook-Pro.local');

    say "$res->{name}";

    # Home dir
    $self->ua->app($class);
    my $home_dir = $self->ua->app->home->to_string;

    my $r = $self->create_repo($home_dir);

    # Add files to repo
    say "add:" . $self->git($r, add => @{$self->app->home->list_files});
    say "commit:" . $self->git($r, commit => '-m' => 'Initial Commit');

    # Add remote
    $self->git($r, remote => add => heroku => $res->{git_url});

    # Push app to heroku
    $self->git($r, push => heroku => 'master');

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

    my $git_dir = $self->tmpdir . '/mojo_deploy_git_' . int rand 1000;

    Git::Repository->run(init => $git_dir);
    return Git::Repository->new(
      work_tree => $home_dir,
      git_dir   => $git_dir . '/.git'
    );
}

sub git {
    my $self = shift;
    my $r    = shift;

    return 1 if eval { $r->run(@_) };
}

sub is_repo {
    return eval { Git::Repository->new(git_dir => pop . '/.git') };
}

1;

=head1 NAME

Mojolicious::Command::deploy::heroku - Deploy to Heroku

=head1 SYNOPSIS

  use Mojolicious::Command::deploy::heroku

  my $deployment = Mojolicious::Command::deploy::heroku->new;
  $deployment->run(@ARGV);

=head1 DESCRIPTION

L<Mojolicious::Command::deployment> deploys a Mojolicious app to Heroku.

=head1 ATTRIBUTES

L<Mojolicious::Command::deploy::heroku> inherits all attributes from
L<Mojo::Command> and implements the following new ones.

=head2 C<description>

  my $description = $deployment->description;
  $cpanify        = $deployment->description('Foo!');

Short description of this command, used for the command list.

=head2 C<usage>

  my $usage = $deployment->usage;
  $deployment  = $deployment->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::deploy::heroku> inherits all methods from L<Mojo::Command>
and implements the following new ones.

=head2 C<run>

  $delpoyment->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
