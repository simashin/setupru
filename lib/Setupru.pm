package Setupru;

use warnings;
use strict;
use utf8;

#use Data::Dumper;
use Setupru::Dispatcher qw(%CONFIG);
use Setupru::Auth qw(login);
use WWW::Mechanize;
use HTTP::Request::Common;
use JSON::XS;
use base qw(Exporter);

our @EXPORT_OK = qw(create_site get_last_site_id enable_order_form 
    create_catalog_page get_auth add_products_to_catalog 
    create_menu_link_for_catalog upload_catalog_imgs tie_img_product);


=head1 Setupru

Модуль для работы с setup.ru

=cut


=head2 create_site($params)

Функция для создания проекта на setup.ru

=head3 Входные параметры

=head4 $params

Хеш. Параметры 
    $params->{agent} - залогиненный на setup.ru объект Mechanize

=head3 Возвращаемые значения 

Нет.

=cut


sub create_site {
    my ($params) = @_;

    $params->{agent}->post(
        $CONFIG{setupru}{links}{create_site},
        [   
            set_id      => $CONFIG{new_site}{type_ids}{set_id}, 
            layout_id   => $CONFIG{new_site}{type_ids}{layout_id}
        ]
    );
}


=head2 create_catalog_page($params)

Создаёт новую страницу(типа каталог) на сайте.

=head3 Входные параметры

=head4 $params

Хеш. Параметры 
    $params->{agent} - залогиненный на setu.ru объект Mechanize
    $params->{new_site_id} - ID проекта на setup.ru

=head3 Возвращаемые значения 

Хеш. Информация о созданом каталоге

=cut

sub create_catalog_page {
    my ($params) = @_;

    my $url = 
        _make_url_by_site_id($CONFIG{setupru}{links}{create_catalog}, $params->{new_site_id});
    
    return 
        decode_json $params->{agent}->post(
            $url,
                [   
                    action_create   => 'create', 
                    data            => encode_json $CONFIG{new_site}{catalog_info},
                ]
        )->content;
}


=head2 create_menu_link_for_catalog($params)

Создаёт ссылку в меню для перехода в каталог.

=head3 Входные параметры

=head4 $params

Хеш. Параметры 
    $params->{agent} - залогиненный на setu.ru объект Mechanize
    $params->{new_site_id} - ID проекта на setup.ru
    $params->{catalog} - Данные по каталогу товаров.

=head3 Возвращаемые значения 

Хеш. Новое меню.

=cut

sub create_menu_link_for_catalog {
    my ($params) = @_;

    my $url = 
        _make_url_by_site_id($CONFIG{setupru}{links}{get_menu}, $params->{new_site_id});
    my $menu = decode_json $params->{agent}->get($url)->content;
    push @{$menu->{menu}}, 
        {
            entity_id   => $params->{catalog}->{id},
            url         => $params->{catalog}->{uri},
            title       => $params->{catalog}->{title},
        };
    my $url_set_menu = 
        _make_url_by_site_id($CONFIG{setupru}{links}{set_menu}, $params->{new_site_id});

    return 
        decode_json $params->{agent}->post(
            $url_set_menu,
            [   
                data            => encode_json $menu,
                location        => ''
            ]
        )->content;
}

=head2 add_products_to_catalog($params)

Добавляет товары в каталог

=head3 Входные параметры

=head4 $params

Хеш. Параметры 
    $params->{agent} - залогиненный на setu.ru объект Mechanize
    $params->{new_site_id} - ID проекта на setup.ru
    $params->{catalog} - Данные по каталогу товаров.

=head3 Возвращаемые значения 

Нет. В процессе работы заполняет хеш с параметрами информацией созданных товарах

=cut

sub add_products_to_catalog {
    my ($params) = @_;
    
    my $url = 
        _make_url_by_site_id($CONFIG{setupru}{links}{add_product}, $params->{new_site_id});
   foreach my $product (keys %{$CONFIG{new_site}{products_info}}) {
        $params->{new_products_info}{$product} = 
            decode_json $params->{agent}->post(
                $url,
                [   
                    block_id        => 'catalog',
                    data            => encode_json $CONFIG{new_site}{products_info}{$product},
                    location        => $params->{catalog}->{uri}
                ]
            )->content;
    }
}


=head2 get_last_site_id($params])

Получает id последнего созданного сайта. Парсит страницу со списком проектов.

=head3 Входные параметры

=head4 $params

Хеш. Параметры 
    $params->{agent} - залогиненный на setu.ru объект Mechanize

=head3 Возвращаемые значения 

Число.
ID сайта.

=cut

sub get_last_site_id {
    my ($params) = @_;

    $params->{agent}->get($CONFIG{setupru}{links}{sites_list});
    my ($id) = $params->{agent}->content =~
        /<a href="http:\/\/(\d+)\.setup\.ru" class="cencel-tab">Редактировать<\/a>/;
    
    return $id;
}


=head2 enable_order_form($params)

Включает интернет магазин на сайте

=head3 Входные параметры

=head4 $params

Хеш. Параметры 
    $params->{agent} - залогиненный на setu.ru объект Mechanize
    $params->{new_site_id} - ID проекта на setup.ru

=head3 Возвращаемые значения 

нет

=cut

sub enable_order_form {
    my ($params) = @_;

    my $url = 
        _make_url_by_site_id($CONFIG{setupru}{links}{set_eshop}, $params->{new_site_id});
    $params->{agent}->post(
        $url,
        [   
            enable_order_form => 'checked', 
        ]
    );
}


=head2 upload_catalog_imgs($params)

Загружает изображения в каталог.

=head3 Входные параметры

=head4 $params

Хеш. Параметры 
    $params->{agent} - залогиненный на setu.ru объект Mechanize
    $params->{new_site_id} - ID проекта на setup.ru

=head3 Возвращаемые значения 

Нет. В процессе работы заполняет хеш с параметрами информацией о загруженных изображениях

=cut

sub upload_catalog_imgs {
    my ($params) = @_;

    my $url = 
        _make_url_by_site_id($CONFIG{setupru}{links}{upload_catalog_img}, $params->{new_site_id});
    foreach my $product (keys %{$CONFIG{new_site}{products_imgs}}) {
        my $img = 
            $CONFIG{new_site}{imgs_dir} 
            . $CONFIG{new_site}{products_imgs}{$product};
        my $request = POST $url,
            Content_Type => 'multipart/form-data', 
            Content => [ file => [$img]];
        $params->{new_products_info}{$product}{img} = 
             $params->{agent}->request($request)->content;
        my %img_info =  
            map {split /: /, $_}
            split /\n/,$params->{new_products_info}{$product}{img};
        $params->{new_products_info}{$product}{img} = \%img_info;
    }
}


=head2 tie_img_product($params)

Связывает товар с его фотографией.

=head3 Входные параметры

=head4 $params

Хеш. Параметры 
    $params->{agent} - залогиненный на setu.ru объект Mechanize
    $params->{new_site_id} - ID проекта на setup.ru
    $params->{new_products_info} - информация о созданых товарах

=head3 Возвращаемые значения 

Нет. 

=cut

sub tie_img_product {
    my ($params) = @_;

    my $url = 
        _make_url_by_site_id($CONFIG{setupru}{links}{tie_img_product}, $params->{new_site_id});
    foreach my $product (keys %{$params->{new_products_info}}) {
        if ( exists $CONFIG{new_site}{products_imgs}{$product} ) {
            $params->{agent}->post(
                $url,
                [   
                    'link'   => $params->{new_products_info}{$product}{img}{File},
                    location => $params->{new_products_info}{$product}{uri},
                ]
            );
        }
    }
}



=head2 get_auth($agent)

Логин на сервис setup.ru

=head3 Входные параметры

=head4 $agent

Объект mechanize

=head3 Возвращаемые значения 

Объект mechanize. Уже залогинненый

=cut

sub get_auth {
    my $agent = WWW::Mechanize->new();
    return login(
        {
            login   => $CONFIG{setupru}{auth}{login},
            passwd  => $CONFIG{setupru}{auth}{passwd},
            agent   => $agent,
            page    => $CONFIG{setupru}{links}{auth}
        }
    );
}


=head2 _make_url_by_site_id($conf_url, $id)

Преобразует урл из конфига, добавляя в него ID проекта

=head3 Входные параметры

=head4 $conf_url, id

$conf_url Строка - урл для вставки ID
$id       Число. ID проекта

=head3 Возвращаемые значения 

Строка. Урл

=cut

sub _make_url_by_site_id {
    my ($conf_url, $id) = @_;
    
    $conf_url =~ s/__SITE_ID__/$id/;
    
    return $conf_url;
}


1;

