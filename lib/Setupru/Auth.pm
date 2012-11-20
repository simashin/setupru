package Setupru::Auth;

use warnings;
use strict;
use utf8;

use base 'Exporter';
our @EXPORT_OK = qw(login);

=head1 Setupru::Auth

Модуль авторизации на setup.ru

=cut


=head2 login($params)

Функция логинится на setup.ru

=head3 Входные параметры

=head4 $params

Хеш. 
$params->{login}    - логин для входа на сервис
$params->{passwd}   - пароль для входа на сервис
$params->{page}     - адрес страницы, где происходит логин
$params->{agent}    - агент Mechanize

=head3 Возвращаемые значения 

Объект агента Mechanize

=cut

sub login {
    my ($params) = @_;

    $params->{agent}->get($params->{page});
    $params->{agent}->field('login', $params->{login});
    $params->{agent}->field('password', $params->{passwd});
    $params->{agent}->submit();

    return $params->{agent};
}


1;

