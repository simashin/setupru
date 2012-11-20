#!/usr/bin/perl

use warnings;
use strict;
use utf8;

#use Data::Dumper;
use lib qw(../lib);
use Setupru qw(create_site get_last_site_id enable_order_form 
    create_catalog_page get_auth create_menu_link_for_catalog 
    add_products_to_catalog upload_catalog_imgs tie_img_product);

=head1 Имя

create_prj.pl

=head1 Описание

Скрипт создаёт простой сайт на setup.ru

=cut

#Создаём хеш, для передачи параметров работы.
my $params;
#Логинимся на сайте.
$params->{agent} = get_auth();
#Cоздаём новый сайт
create_site($params);
#Получаем ID последнего созданного сайта
$params->{new_site_id} = get_last_site_id($params);
#Включаем интернет магазин на этом сайте
enable_order_form($params);
#Создаём каталог на сайте, для отображения товара.
$params->{catalog} = create_catalog_page($params);
#Создаём сылку в меню на каталог
create_menu_link_for_catalog($params);
#Добавляем товары в каталог
$params->{product} = add_products_to_catalog($params);
#Загружаем картинки в каталог
upload_catalog_imgs($params);
#Привязываем картинки к товарам
tie_img_product($params);

