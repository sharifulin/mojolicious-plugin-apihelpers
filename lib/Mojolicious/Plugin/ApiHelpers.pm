package Mojolicious::Plugin::ApiHelpers;
use base 'Mojolicious::Plugin';

use strict;
use warnings;

our $VERSION = '0.1';

our $ERROR = {
	1 => 'Unknown error occured',
	2 => 'User authorization failed',
	3 => 'Request denied',
	4 => 'Bad parameters',
	5 => 'Bad request',
	
	30 => 'Bad location',
	44 => 'Not found',
};

sub register {
	my ($self, $app, $conf) = @_;
	
	my $error_msg = { %$ERROR };
	$error_msg->{$_} = $conf->{error_msg}->{$_} for keys %{$conf->{error_msg}||{}};
	
	$app->renderer->add_helper(api_list => sub {
		my $self = shift;
		my($type, $list) = @_;
		my $normalize; $normalize = sub { 
			my ($data, $class) = @_;
			
			given (ref $data) {
				when('HASH') {
					for (keys %$data) {
						if (ref $data->{$_}) {
							$normalize->($data->{$_},$_);
						} else {
							next unless my $t = 
								$conf->{'field'}->{$_}
								 or 
								$class ? $conf->{'class'}->{$class}->{$_} : ''
							;
							
							$data->{$_} =
								$t eq 'int'    ? int $data->{$_} :
								$t eq 'string' ? "$data->{$_}"   :
								$t eq 'float'  ? $data->{$_} + 0 : $data->{$_}
							;
						}
					}
				}
				when('ARRAY') {
					$normalize->($_) for grep { ref $_ } @$data;
				}
			};
			
			return $data;
		};
		
		return $self->render_json({
			$type => {
				list   => $normalize->($list),
				params => $self->req->params->to_hash,
			},
		});
	});
	
	$app->renderer->add_helper(api_error => sub {
		my $self  = shift;
		my $param = { @_ };
		
		my $code  = $param->{code} || 1;
		my $msg   = $error_msg->{ $code };
		
		$msg .= ': ' . join(', ', sort keys %{ $param->{params} || {}}) if $code == 4 && %{ $param->{params} || {}};
		
		my $error = {
			error => {
				code => $code,
				msg  => $msg,
				
				$param->{subcode} ? ( subcode => $param->{subcode}, submsg => $error_msg->{ $param->{subcode} }) : (),
				$param->{params } ? ( params  => $param->{params } ) : (),
			},
		};
		return $self->render_json( $error );
	});
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::ApiHelpers - some API helpers

=head1 SYNOPSIS

	# Mojolicious
	$self->plugin('api_helpers');
	
	# Mojolicious::Lite
	plugin 'api_helpers';
	
	# or
	plugin 'api_helpers', { error_msg => { 99 => 'Foo Bar error' } };

	get '/list.json' => sub {
		$self->helper('api_list', test => [ ... ]);
	};
	
	get '/one.json' => sub {
		return $self->helper('api_error', code => 4, params => { id => 'required' })
			unless $self->req->param('id');
		
		...
	};

=head1 DESCRIPTION

L<Mojolicous::Plugin::ApiHelpers> is a plugin contains some helpers for API.

=head1 METHODS

L<Mojolicious::Plugin::ApiHelpers> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

	$plugin->register;

Register plugin hooks in L<Mojolicious> application.


=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Anatoly Sharifulin <sharifulin@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-apihelpers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.htMail?Queue=Mojolicious-Plugin-apihelpers>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=over 5

=item * Github

L<http://github.com/sharifulin/Mojolicious-Plugin-apihelpers/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.htMail?Dist=Mojolicious-Plugin-apihelpers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-apihelpers>

=item * CPANTS: CPAN Testing Service

L<http://cpants.perl.org/dist/overview/Mojolicious-Plugin-apihelpers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-apihelpers>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-apihelpers>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010, 2013 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
