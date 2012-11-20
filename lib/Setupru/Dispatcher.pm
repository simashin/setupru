package Setupru::Dispatcher;

use warnings;
use strict;
use utf8;
use open qw[:std :utf8];

use File::Basename qw(dirname);
#use POSIX qw(strftime);
use YAML::Tiny;

use base 'Exporter';

our %CONFIG = ();
our @EXPORT_OK = qw(%CONFIG);


=head1 Setupru::Dispatcher

Содержит вспомогательные функции

=cut


config();


=head2 config()

Функция возвращает параметры конфигурации. Устанавливает глобавльную переменную %CONFIG

=head3 Входные параметры

=head4 Нет

=head3 Возвращаемые значения 

Хэш

=cut

sub config {
    unless (keys(%CONFIG)) {
        our $config = 
            YAML::Tiny->read(dirname(__FILE__) . '/../../setupru_test.conf');
        %CONFIG = %{$config->[0]};
    }
    return \%CONFIG;
}


1;

