use strict;
use warnings;
use Test::More tests => 1;
use Plack::Test;
use HTTP::Request::Common;
use utf8;
use Encode;
use Module::Runtime 'use_module';
use Dancer2::Serializer::XML;

my $serializer = Dancer2::Serializer::XML->new();

{
    package App;
    use Dancer2;

    # default, we're actually overriding this later
    set serializer => 'XML';

    # for now
    set logger     => 'Console';

    put '/from_params' => sub {
        my %p = params();
        return [ map +( $_ => $p{$_} ), sort keys %p ];
    };
}

my $app = App->to_app;
note "Verify Serializers decode into characters"; {
    my $utf8 = '∮ E⋅da = Q,  n → ∞, ∑ f(i) = ∏ g(i)';

    test_psgi $app, sub
    {
        my $cb = shift;

		my $body = $serializer->serialize({utf8 => $utf8});

		my $r = $cb->(
			PUT '/from_params',
				'Content-Type' => $serializer->content_type,
				Content        => $body,
		);
		
		my $content = Encode::decode( 'UTF-8', $r->content );

		like($content, qr{\Q$utf8\E}, "utf-8 string returns the same using the serializer");
    };
}

