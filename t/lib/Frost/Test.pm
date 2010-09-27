package Frost::Test;

use strict;
use warnings;

BEGIN
{
	my $odef = select STDERR;
	$| = 1;
	select STDOUT;
	$| = 1;
	select $odef;
}

package main;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;

use Frost::Util;

use Frost::TestPath;

our $MAKE_MUTABLE	= $ENV{Frost_MAKE_MUTABLE};

diag ( "\n>>>>>>>>>>>>>>> MUTABLE TEST! <<<<<<<<<<<<<<<\n" )		if $MAKE_MUTABLE;

#	stolen from Test::More 0.78 and changed (#X):
#
sub ISA_NOT ($$;$)
{
	my ( $object, $class, $obj_name )	= @_;

	my $tb		= Test::More->builder;
	my $diag;
	$obj_name	= 'The object'		unless defined $obj_name;
#X	my $name		= "$obj_name isa $class";
	my $name		= "$obj_name is NOT a $class";

	if		( !defined $object )
	{
		$diag = "$obj_name isn't defined";
	}
	elsif	( !ref $object )
	{
		$diag = "$obj_name isn't a reference";
	}
	else
	{
		# We can't use UNIVERSAL::isa because we want to honor isa() overrides
		my ( $rslt, $error )	= $tb->_try ( sub { $object->isa ( $class ) } );

		if		( $error )
		{
			if ( $error =~ /^Can\'t call method "isa" on unblessed reference/ )
			{
				# Its an unblessed reference
				if ( !UNIVERSAL::isa($object, $class) )
				{
					my $ref = ref $object;
					$diag = "$obj_name isn't a '$class' it's a '$ref'";
				}
			}
			else
			{
				die <<WHOA;
WHOA! I tried to call ->isa on your object and got some weird error.
Here\'s the error.
$error
WHOA

			}
		}
#X		elsif	( ! $rslt )
#X		{
#X			my $ref = ref $object;
#X			$diag = "$obj_name isn't a '$class' it's a '$ref'";
#X		}
#X	NEW
#X
		elsif	( ! $rslt )
		{
			#	ok	!
		}
		elsif	( $rslt )
		{
			$diag = "$obj_name isa '$class', but shouldn't";
		}
#X
#X	####
	}

	my $ok;

	if ( $diag )
	{
		$ok	= $tb->ok ( 0, $name );
		$tb->diag ("    $diag\n" );
	}
	else
	{
		$ok	= $tb->ok ( 1, $name );
	}

	return $ok;
}

sub CAN_NOT ($@)
{
	my ( $proto, @methods ) = @_;

	my $class = ref $proto || $proto;

	my $tb = Test::More->builder;

	unless ( $class )
	{
#X		my $ok = $tb->ok( 0, "->can(...)" );
		my $ok = $tb->ok( 0, "->can NOT (...)" );
#X		$tb->diag('    can_ok() called with empty class or reference');
		$tb->diag('    CAN_NOT() called with empty class or reference');
		return $ok;
	}

	unless ( @methods )
	{
#X		my $ok = $tb->ok( 0, "$class->can(...)" );
		my $ok = $tb->ok( 0, "$class->can NOT (...)" );
#X		$tb->diag('    can_ok() called with no methods');
		$tb->diag('    CAN_NOT() called with no methods');
		return $ok;
	}

	my @nok = ();

	foreach my $method (@methods)
	{
#X		$tb->_try(sub { $proto->can($method) }) or push @nok, $method;
		$tb->_try(sub { $proto->can($method) }) and push @nok, $method;
	}

	my $name;

#X	$name = @methods == 1 ? "$class->can('$methods[0]')" : "$class->can(...)";
	$name = @methods == 1 ? "$class->can NOT ('$methods[0]')" : "$class->can NOT (...)";

	my $ok = $tb->ok( !@nok, $name );

#X	$tb->diag(map "    $class->can('$_') failed\n", @nok);
	$tb->diag(map "    $class->can('$_') but shouldn't\n", @nok);

	return $ok;
}

my ( $INFO, @INFO, $CPU_NAME, $CPU_SPEED, $RAM_SIZE, $PERL_VERSION );

{
	no warnings;

	$INFO	= `/bin/cat /proc/cpuinfo`;
	@INFO	= split /\n/, $INFO;

	for ( @INFO )
	{
		if ( m/^model name\s+:\s+(.+)$/i )
		{
			$CPU_NAME	= $1;
		}

		if ( m/^cpu MHz\s+:\s+(.+)$/i )
		{
			$CPU_SPEED	= $1;
			$CPU_SPEED	= sprintf ( '%4.1f', $CPU_SPEED / 1000 );		#	GHz
		}
	}

	$INFO	= `/bin/cat /proc/meminfo`;
	@INFO	= split /\n/, $INFO;

	for ( @INFO )
	{
		if ( m/^MemTotal:\s+(\d+)/i )
		{
			$RAM_SIZE	= $1;
			$RAM_SIZE	= sprintf ( '%5d', $RAM_SIZE / 1024 );		#	MB
		}
	}

	$PERL_VERSION	= sprintf "v%vd", $^V;
	$PERL_VERSION	= sprintf "%-8s", $PERL_VERSION;

	$CPU_NAME		||= 'undef';
	$CPU_SPEED		||= 'undef';
	$RAM_SIZE		||= 0;
	$PERL_VERSION	||= 'undef';
}

sub TF_CPU_NAME	()	{ $CPU_NAME		}
sub TF_CPU_SPEED	()	{ $CPU_SPEED	}
sub TF_RAM_SIZE	()	{ $RAM_SIZE		}

sub TF_RAM_FREE	()
{
	no warnings;

	$INFO	= `/bin/cat /proc/meminfo`;
	@INFO	= split /\n/, $INFO;

	my $free;

	for ( @INFO )
	{
		if ( m/^MemFree:\s+(\d+)/i )
		{
			$free	= $1;
			$free	= sprintf ( '%5d', $free / 1024 );		#	MB
		}
	}

	defined $free		or return - TF_RAM_SIZE;

	$free;
}

sub TF_RAM_USED	()
{
	TF_RAM_SIZE - TF_RAM_FREE;
}

sub TF_PERL_VERSION	()	{ $PERL_VERSION }

sub TF_DISK_SPEED	()
{
	my $size			= 256;			#	MB
	my $filename	= '/tmp/frost_test_speed';

	my $chunk		= ( 'X' x 1023 ) . "\n";

	my $max_chunk	= $size * 1024;

	my ( $success, $t0, $t1, $t2, $td, $mb_sec );

	unlink $filename		if -e $filename;

	$success	= open SPEED_TEST, ">$filename";

	if ( $success )
	{
		my $oldfh = select(SPEED_TEST); $| = 1; select($oldfh);	#	unbuffer

		$t0		= Time::HiRes::gettimeofday();

		for ( my $i = 0; $i < $max_chunk; $i++ )
		{
			last		unless $success;

			$success	= print SPEED_TEST $chunk;
		}

		$success	= close SPEED_TEST			if $success;
	}

	if ( $success )
	{
		$t1		= Time::HiRes::gettimeofday() - $t0;

#		print STDERR "\n-----> WRITE $size MB $t1\n";
	}

	$success	= open SPEED_TEST, "<$filename";

	if ( $success )
	{
		my $oldfh = select(SPEED_TEST); $| = 1; select($oldfh);	#	unbuffer

		for ( my $i = 0; $i < $max_chunk; $i++ )
		{
			last		unless $success;

			$success	= <SPEED_TEST>;
		}

		$success	= close SPEED_TEST			if $success;
	}

	if ( $success )
	{
		$t2		= Time::HiRes::gettimeofday() - $t0 - $t1;

#		print STDERR "-----> READ  $size MB $t2\n";
	}

	if ( $success )
	{
		my $write_mb_sec	= $t1 > 0 ? int ( $size / $t1 ) : -1;
		my $read_mb_sec	= $t2 > 0 ? int ( $size / $t2 ) : -1;

#		print STDERR "-----> WRITE $write_mb_sec MB\n";
#		print STDERR "-----> READ  $read_mb_sec MB\n";

		$mb_sec	= int ( ( $write_mb_sec + $read_mb_sec ) / 2 );

#		print STDERR "-----> I/O   $mb_sec MB\n";
	}
	else
	{
		$mb_sec	= -2;
	}

	unlink $filename		if -e $filename;

	return $mb_sec;
}

1;

__END__
