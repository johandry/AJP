#!/usr/bin/perl

#Title       : AJP.pl
#Date Created: Thu, Jan 31, 2013 10:35:52 AM
#Last Edit   : Thu, Jan 31, 2013 10:35:52 AM
#Author      : "Johandry Amador" < Johandry.Amador@softtek.com >
#Version     : 1.00
#Description : This script will receive a list of Autosys Jobs in JIL format and will create several documents with useful and easy to understand information.
#Usage       : AJP.pl [--help or -h] [--verbose] _USAGE_

# Requirements:
# _REQUIREMENT_ 

# General TODO's:
# _TODO_

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

# Global variables
my %JOB_TYPES = (
	'b' => 'Box',
	'c' => 'Child',
	'f' => 'File watcher'
);

my @JOB_FIELDS = qw/id name type box_name command machine owner permission date_condition days_of_week start_times condition description std_out_file std_err_file alarm_if_fail/;

# Options or script parameters handling section

our $VERSION=2.00;
my $debug='';
my $verbose='';
my $help='';
my $jobsFile='alljobs.txt';
my $outFile='-';
my $generalCSV='';
my $boxesCSV='';
my $printJobs='';
my $query='';
my $count='';
my $list_fields='';


#Getopt::Long::Configure ("bundling", "ignorecase_always");
GetOptions(
  'debug'=>\$debug,
  'verbose'=>\$verbose,
  'help|?'=>\$help,
  'jobs=s'=>\$jobsFile,
  'output=s'=>\$outFile,
  'general'=>\$generalCSV,
  'boxes'=>\$boxesCSV,
  'print_jobs'=>\$printJobs,
  'query=s'=>\$query,
  'count=s'=>\$count,
  'list_fields'=>\$list_fields
  
  ) or pod2usage(2);
pod2usage(1) if $help;

print STDERR "Parameters: \n\tVerbose: $verbose\n\tHelp: $help\n\t  \n" if $debug;

# Subrutine code section
sub printJob {
	my %job = %{ shift() };
	
	print "Information for Job ",exists $job{id}?$job{id}:'UNKNOWN',"\n";
	print "\tJob ID: $job{id}\n";
	print "\tJob Name: $job{name}\n" if exists $job{name};
	print "\tJob Type: $job{type}\n" if exists $job{type}; 
	print "\tJob Box Name: $job{box_name}\n" if exists $job{box_name};
	print "\tJob Command: $job{command}\n" if exists $job{command};
	print "\tJob Machine: $job{machine}\n" if exists $job{machine};
	print "\tJob Owner: $job{owner}\n" if exists $job{owner};
	print "\tJob Permission: $job{permission}\n" if exists $job{permission};
	print "\tJob Date Condition: $job{date_condition}\n" if exists $job{date_condition};
	print "\tJob Days of Week: $job{days_of_week}\n" if exists $job{days_of_week};
	print "\tJob Start Times: $job{start_times}\n" if exists $job{start_times};
	print "\tJob Condition: $job{condition}\n" if exists $job{condition};
	print "\tJob Description: $job{description}\n" if exists $job{description};
	print "\tJob Standard Out File: $job{std_out_file}\n" if exists $job{std_out_file};
	print "\tJob Standard Error File: $job{std_err_file}\n" if exists $job{std_err_file};
	print "\tJob Alarm if Fails: $job{alarm_if_fail}\n" if exists $job{alarm_if_fail};
}

sub printJobs {
	my @jobs = @{ shift() }; 
	
	open OUTPUT, ">$outFile" or die "Cannot open output $outFile. $!";
	my $oldfh = select(OUTPUT);
	printJob($_) foreach (@jobs);
	$|=1;
	select($oldfh);
	close OUTPUT;
}

sub addJob {
	my $job_id = shift;
	my @jobs = @{ shift() };
	my %job  = %{ shift() };
	
	push @jobs, {
		id 				=> $job_id, 
		name 			=> exists $job{name}?$job{name}:'', 
		type 			=> exists $job{type}?$job{type}:'',
		box_name		=> exists $job{box_name}?$job{box_name}:'',
		command			=> exists $job{command}?$job{command}:'',
		machine			=> exists $job{machine}?$job{machine}:'',
		owner			=> exists $job{owner}?$job{owner}:'',
		permission		=> exists $job{permission}?$job{permission}:'',
		date_condition	=> exists $job{date_condition}?$job{date_condition}:'',
		days_of_week	=> exists $job{days_of_week}?$job{days_of_week}:'',
		start_times		=> exists $job{start_times}?$job{start_times}:'',
		condition		=> exists $job{condition}?$job{condition}:'',
		description		=> exists $job{description}?$job{description}:'',
		std_out_file	=> exists $job{std_out_file}?$job{std_out_file}:'',
		std_err_file	=> exists $job{std_err_file}?$job{std_err_file}:'',
		alarm_if_fail	=> exists $job{alarm_if_fail}?$job{alarm_if_fail}:''	
		};
	return @jobs;
}

sub getJobs {
	my $file=shift;
	
	my %job = ();
	my @jobs;
	my $job_id = 1;
	
	open SOURCE, "<$file" or die "Cannot open $file. $!";
	while (<SOURCE>) {
		# Remove end of line Unix and DOS style.
		chomp;
		s/\r//g;
		# If the next job is found, add the previous one and clear the hash for the next.
		if (/insert_job:/ and %job) {
			@jobs = addJob $job_id++, \@jobs, \%job;
			printJob($jobs[-1]) if $debug;
			%job = ();
		}
		
		$job{name} 			= $1 if /insert_job: (\w+)/; 
		$job{type} 			= ($1 eq 'b')?$JOB_TYPES{'b'}:($1 eq 'c')?$JOB_TYPES{'c'}:($1 eq 'f')?$JOB_TYPES{'f'}:'Unknown' if /job_type: (\w+)/;
		$job{box_name}		= $1 if /box_name: (\w+)/;
		$job{command}		= $1 if /command: (.+)/;
		$job{machine}		= $1 if /machine: (.+)/;
		$job{owner}			= $1 if /owner: (.+)/;
		$job{permission}	= "\"$1\"" if /permission: (.+)/;
		$job{date_condition}= $1 if /date_conditions: (.+)/;
		$job{days_of_week}	= "\"$1\"" if /days_of_week: (.+)/;
		$job{start_times}	= "\"$1\"" if /start_times: "(.+)"/;
		$job{condition}		= $1 if /condition: (.+)/;	
		$job{std_out_file}	= $1 if /std_out_file: (.*)/;
		$job{std_err_file}	= $1 if /std_err_file: (.*)/;
		$job{alarm_if_fail}	= $1 if /alarm_if_fail: (.+)/;
		if (/description: "(.*)"/) {
			my $desc = $1;
			$desc =~ s/"/""/g;
			$desc = "\"$desc\"";
			$job{description}	= $desc;
		}
	}
	# Push the last one.
	if (%job) {
		@jobs = addJob $job_id, \@jobs, \%job;
		printJob($jobs[-1]) if $debug;
	}
	
	print "Total Jobs processed: ",$job_id,"\n" if $verbose;
	#print "Total Jobs processed: ",$#jobs+1,"\n" if $verbose;
	close SOURCE;
	
	return @jobs;
}

sub createGeneralCSV {
	my @jobs = @{ shift() };
	my $csvFile = shift;
	
	open CSVFILE, ">$csvFile" or die "Cannot create CSV file $csvFile. $!";
	
	print CSVFILE join(',', @JOB_FIELDS);
	print CSVFILE "\n";
	
	foreach (@jobs) {
		my %job = %{$_};
		foreach (@JOB_FIELDS) {
			print CSVFILE "," if $_ ne 'id';
			print CSVFILE $job{$_} if exists $job{$_};
		}
		print CSVFILE "\n";
	}
	
	close CSVFILE;
}

sub createBoxesCSV {
	my @jobs = @{ shift() };
	my $csvFile = shift;
	
	open CSVFILE, ">$csvFile" or die "Cannot create CSV file $csvFile. $!";
	
	print CSVFILE "box id, box name, childs count, childs id, childs name\n";
	foreach (@jobs) {
		my %job_box = %{$_};
		# If it is a box, take its childs
		if( $job_box{type} eq $JOB_TYPES{b} ) {
			my @childs_id = ();
			my @childs_name = ();
			foreach (@jobs) {
				my %job_child = %{$_};
				if( $job_child{box_name} eq $job_box{name}) {
					push @childs_id, $job_child{id};
					push @childs_name, $job_child{name};
				}
			}
			print CSVFILE $job_box{id},",",$job_box{name},",",$#childs_id - 1,",\"",join(', ', @childs_id),"\",\"",join(', ', @childs_name),"\"\n";
		}
	}
	
	close CSVFILE;
}

sub printSearchFields {
	print join "\n", @JOB_FIELDS;
	exit 1;
}

sub searchJobs {
	my @jobs = @{ shift() };
	my $queries = shift;
	my @jobs_search;
	
	
	foreach my $query (split /&/, $queries) {
		my ($field, $parameter) = split /=/, $query;
		my @parameters = split /,/, $parameter;
		die "Field name $field is not a valid search file. Use '$0 -list_fields' to list the valid fields\n" if( ! grep {$_ eq $field} @JOB_FIELDS );
		
		foreach (@jobs) {
			my %job = %{$_};
			my $value = $job{"$field"};
			push @jobs_search, \%job if( grep { $value =~ /$_/ } @parameters );
		}
		@jobs = @jobs_search;
		@jobs_search = ();
	}
	return @jobs;
}



# Main code section
printSearchFields if $list_fields;

my @jobs = getJobs($jobsFile);
printJobs(\@jobs) if $printJobs;
createGeneralCSV(\@jobs, $outFile) if $generalCSV;
createBoxesCSV(\@jobs, $outFile) if $boxesCSV;
$query = $count if $query eq '' and $count;
if( $query ) {
	my @jobs_search = searchJobs(\@jobs, $query);
	if( $count ) {
		print "Found ",scalar @jobs_search,"/",scalar @jobs," jobs\n";
	} else {
		createGeneralCSV(\@jobs_search, $outFile) if @jobs_search;
	}
}

# Documentation pod section

__END__

=head1 NAME

AJP.pl - This script will receive a list of Autosys Jobs in JIL format and will create several documents with useful and easy to understand information. 

=head1 SYNOPSIS

AJP.pl [--help or -h] [--verbose] _USAGE_

 Options:
   --help    or -h                         Brief help message
   --verbose                               Provide more information. Useful for debugging.


=head1 OPTIONS

=over 8

=item B<--help> or B<-h>

Print a brief help message and exits.

For more information enter: B<perldoc AJP.pl>

=item B<--verbose>

Print more information, useful for debugging purposes. 

The verbose output is sent to the Standar Error so you may send the verbose to a file using this at the end of the command: 2>delete.me



=back

=head1 DESCRIPTION

B<This program> This script will receive a list of Autosys Jobs in JIL format and will create several documents with useful and easy to understand information..

B<Author>: "Johandry Amador" < Johandry.Amador@softtek.com >

=cut

