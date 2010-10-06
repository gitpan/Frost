use warnings;
use strict;

use DB_File();

sub lprint
{
	print @_, "\n";
}


lprint 'Checking Berkeley DB...';
lprint 'VERSIONS:';
lprint 'Perl       ' . $];
lprint 'DB_File    ' . $DB_File::VERSION;
lprint "           Built   with Berkeley DB $DB_File::db_ver";
lprint "           Running with Berkeley DB $DB_File::db_version";

if ( $DB_File::db_version < 4 )
{
	die 'Need BerkeleyDB version 4.0, this is only ' . $DB_File::db_version;
}

lprint 'Looks good';


