#!/usr/bin/perl -w
# $Id$
#
# t/schema.t -- Tests for the wallet schema class.
#
# Written by Russ Allbery <rra@stanford.edu>
# Copyright 2007 Board of Trustees, Leland Stanford Jr. University
#
# See LICENSE for licensing terms.

use Test::More tests => 10;

use DBI;
use Wallet::Schema;

use lib 't/lib';
use Util;

my $schema = Wallet::Schema->new;
ok (defined $schema, 'Wallet::Schema creation');
ok ($schema->isa ('Wallet::Schema'), ' and class verification');
my @sql = $schema->sql;
ok (@sql > 0, 'sql() returns something');
is (scalar (@sql), 26, ' and returns the right number of statements');

# Create a SQLite database to use for create.
my $dbh = DBI->connect ("DBI:SQLite:wallet-db");
if (not defined $dbh) {
    die "cannot create database wallet-db: $DBI::errstr\n";
}
$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;
eval { $schema->create ($dbh) };
is ($@, '', "create() doesn't die");

# Test dropping the database.
eval { $schema->drop ($dbh) };
is ($@, '', "drop() doesn't die");
my $sql = "select name from sqlite_master where type = 'table'";
my $sth = $dbh->prepare ($sql);
$sth->execute;
my ($table, @tables);
while (defined ($table = $sth->fetchrow_array)) {
    push (@tables, $table) unless $table =~ /^sqlite_/;
}
is ("@tables", '', ' and there are no tables in the database');
eval { $schema->create ($dbh) };
is ($@, '', ' and we can run create again');

# Clean up.
eval { $schema->drop ($dbh) };
unlink 'wallet-db';

# Now repeat the test against the configured database in case it's different.
db_setup;
my $connect = "DBI:${Wallet::Config::DB_DRIVER}:${Wallet::Config::DB_INFO}";
my $user = $Wallet::Config::DB_USER;
my $password = $Wallet::Config::DB_PASSWORD;
$dbh = DBI->connect ($connect, $user, $password);
if (not defined $dbh) {
    die "cannot connect to database $connect: $DBI::errstr\n";
}
$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;
eval { $schema->create ($dbh) };
is ($@, '', "create() against configured database doesn't die");
eval { $schema->drop ($dbh) };
is ($@, '', " and drop() doesn't die");
