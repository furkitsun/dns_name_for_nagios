#!/usr/bin/perl -w
##########################################################
#
#               Name : check_name
#               Author : Chenu Tristan
#
#
##########################################################
use DBI;
use Getopt::Long;

my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);
my $Name = "check_name";
my $o_host = undef;
my $o_nameserver = undef;
my $o_help = undef;

#usage
sub print_usage{
        print "Usage: $Name --host <host address> --nameserver <dns server> [-h]\n";
}
#for help
sub help {
        print "dynamic host name\n";
        print_usage();
}
#check si'il y a des options
sub check_opt(){
        Getopt::Long::Configure ("bundling");
        GetOptions(
                'hostname:s' =>\$o_host,        'nameserver:s'=>\$o_nameserver,
                'h' => \$o_help
);
        if(defined($o_help)) {help();exit $ERRORS{'UNKNOWN'};};
        if(!defined(\$o_host) || !defined(\$o_nameserver)){ print "Invalid host or nameserver";exit $ERRORS{'UNKNOWN'};};
}
#on extrait le nom d'hôte
sub lookup_host($$){
        my $command = `host \"$_[0]\" \"$_[1]\"`;
        my @command_split = split("\n",$command);
        $command = $command_split[$#command_split];
         @command_split = split(" ",$command);
         $command = $command_split[$#command_split];
         @command_split = split("\\.",$command);
        my $name_host = $command_split[0];
        return $name_host;
}
#on modifier la valeur du nom d'hôte dans lilac
sub connect_to_base($$){
        my $name = $_[1];
        my $host_ip = $_[0];
        my $bd = 'lilac';
        my $serveur = 'localhost';
        my $identifiant = 'lilac';
        my $motdepasse = 'root66';
        my $dbh = DBI->connect("DBI:mysql:database=$bd;host=$serveur",$identifiant,$motdepasse,{
        RaiseError => 1,
}) or die "Connection impossible";
        my $sql_mod_name = "update nagios_host set name= ?  where address= ? ;";
        my $req = $dbh->prepare($sql_mod_name)or die "impossible de préparer la requête.";
        $req->bind_param(1,$name);
        $req->bind_param(2,$host_ip);
        print "$name : $host_ip \n";
        $req->execute() or die "impossible de modifier la table hôte.";
        $req->finish;
        $dbh->disconnect;
        print("la modification a été effectué.\n")

}
#on applique la configuration a nagios sans redémarer le serveur.
sub appliquer_mod(){
        `/srv/eyesofnetwork/nagios/bin/nagios -v /tmp/lilac-export-1/nagios.cfg`;
        print "La configuration a été appliqué.\n";
}

check_opt();
#si l'hote et le dns est definie on execute :
my $name_host = lookup_host($o_host,$o_nameserver) if defined($o_host) and defined($o_nameserver);
#si l'hote et qu'il ny pas un message d'erreur venant du dns on execute:
connect_to_base($o_host,$name_host) if defined($o_host) and defined($name_host) and $name_host ne "3(NXDOMAIN)";
#on execute :
appliquer_mod();
#on retourne OK
exit $ERRORS{'OK'};
