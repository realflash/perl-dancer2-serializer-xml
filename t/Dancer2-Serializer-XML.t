use strict;
use warnings;
use Test::More tests => 7;
use Plack::Test;
use HTTP::Request::Common;
use utf8;
use Encode;
use Module::Runtime 'use_module';
use Dancer2::Serializer::XML;
use Dancer2::Serializer::JSON;
use Dancer2 0.205000;	# We need a minimum version of 0.205000 due to https://github.com/PerlDancer/Dancer2/issues/1302


# Test 1: check stuff gets deserialised
my $serializer = Dancer2::Serializer::XML->new();						# reset serialiser for next test
my $ref = $serializer->deserialize('<data><foo>one</foo><bar>two</bar></data>');
is_deeply(
	$ref,
	{
		bar => 'two',
		foo => 'one'
    },
	"Strings get deserialized");

# Test 2: check stuff gets serialised
$serializer = Dancer2::Serializer::XML->new();							# reset serialiser for next test
my $string = $serializer->serialize({foo => 'one', bar => 'two'});
is($string, '<opt bar="two" foo="one" />
', "Strings get serialized");

# Test 3: check UTf-8 is handled
$serializer = Dancer2::Serializer::XML->new();							# reset serialiser for next test
{
    package UTF8App;
    use Dancer2;

    set serializer => 'XML';
    set logger     => 'Console';

    put '/from_params' => sub {
        my %p = params();
        return [ map +( $_ => $p{$_} ), sort keys %p ];
    };
}
my $app = UTF8App->to_app;
#~ note "Verify Serializers decode into characters"; {
{
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

# Test 4: check settings take effect
$serializer = Dancer2::Serializer::XML->new();							# reset serialiser for next test
my $test_xml_options = { 'serialize' => { RootName => 'test',
										KeyAttr => []
										},
						'deserialize' => { ForceContent => 1,
										KeyAttr => [],
										ForceArray => 1,
										KeepRoot => 1
										}
						};
{
    package NonDefaultApp;
    use Dancer2;

    set serializer => 'XML';
    set logger     => 'Console';

    put '/from_body' => sub {
	my $self = shift;
	$self->{'serializer_engine'}->{'xml_options'} = $test_xml_options;
        return request->data();	# Right back at you
    };
}
$app = NonDefaultApp->to_app;
{
    test_psgi $app, sub
    {
        my $cb = shift;
        $serializer->xml_options($test_xml_options);
		my $body = $serializer->serialize({foo => 'one', bar => 'two'});
		my $r = $cb->(
			PUT '/from_body',
				'Content-Type' => $serializer->content_type,
				Content        => $body,
		);
		#diag("Body: ". $body);
		is($r->content, '<test bar="two" foo="one" />
', "serializers take note of settings");
    };
}

# Test 5: check content type is right
$serializer = Dancer2::Serializer::XML->new();							# reset serialiser for next test
is(
    $serializer->content_type,
    'application/xml',
    'content-type is set correctly',
);

# Test 6: send_as function works
$serializer = Dancer2::Serializer::XML->new();							# reset serialiser for next test
{
    package SendAsApp;
    use Dancer2;

    set serializer => 'JSON';
    set logger     => 'Console';

    put '/from_body' => sub {
		my $self = shift;
		#~ debug request->data();
        send_as XML => request->data();	# Right back at you
    };
}
$app = SendAsApp->to_app;
{
    test_psgi $app, sub
    {
        my $cb = shift;
		my $body = Dancer2::Serializer::JSON->serialize({foo => 'one', bar => 'two'});
		my $r = $cb->(
			PUT '/from_body',
				'Content-Type' => $serializer->content_type,
				Content        => $body,
		);
		#~ diag("Body: ". $body);
		is($r->content, '<opt bar="two" foo="one" />
', "send_as works");
    };
}

# Test 7: send_as function works, complete with options
$serializer = Dancer2::Serializer::XML->new();							# reset serialiser for next test
{
    package SendAsWithOptionsApp;
    use Dancer2;

    set serializer => 'JSON';
    set logger     => 'Console';

    put '/from_body' => sub {
		my $self = shift;
		$self->{'config'}->{'engines'}{'serializer'}{'XML'} = $test_xml_options;
        send_as XML => request->data();	# Right back at you
    };
}
$app = SendAsWithOptionsApp->to_app;
{
    test_psgi $app, sub
    {
        my $cb = shift;
        $serializer->xml_options($test_xml_options);
		my $body = Dancer2::Serializer::JSON->serialize({foo => 'one', bar => 'two'});
		my $r = $cb->(
			PUT '/from_body',
				'Content-Type' => $serializer->content_type,
				Content        => $body,
		);
		is($r->content, '<test bar="two" foo="one" />
', "send_as works with options");
    };
}
