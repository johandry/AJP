#!/usr/bin/perl

#Title       : AJP.pl
#Date Created: Thu, Jan 31, 2013 10:35:52 AM
#Last Edit   : Thu, Jan 31, 2013 10:35:52 AM
#Author      : "Johandry Amador" < Johandry.Amador@softtek.com >
#Version     : 1.00
#Description : This script will receive a list of Autosys Jobs in JIL format and will create several documents with useful and easy to understand information.
#Usage       : AJP.pl [--help or -h] [--verbose] [--debug or -d] [--jobs=filename or -j filename] [--output=filename or -o filename] [--general or -g] [--boxes or -b] [--print_jobs or -p] [--query=query or -q query] [--count=query or -c query] [--list_fields or -l] [--sequence or -s] [--forecast=filename or -f filename]

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
my $jobsFile='alljobs.jil';
my $outFile='-';
my $generalCSV='';
my $boxesCSV='';
my $printJobs='';
my $query='';
my $count='';
my $list_fields='';
my $sequence='';
my $forecast='';


#Getopt::Long::Configure ("bundling", "ignorecase_always");
GetOptions(
  'debug'		=>\$debug,
  'verbose'		=>\$verbose,
  'help|?'		=>\$help,
  'jobs=s'		=>\$jobsFile,
  'output=s'	=>\$outFile,
  'general'		=>\$generalCSV,
  'boxes'		=>\$boxesCSV,
  'print_jobs'	=>\$printJobs,
  'query=s'		=>\$query,
  'count=s'		=>\$count,
  'list_fields'	=>\$list_fields,
  'sequence'	=> \$sequence,
  'forecast=s'	=> \$forecast

  ) or pod2usage(2);
  
pod2usage if $help;

print STDERR "Parameters: \n\tVerbose: $verbose\n\tHelp: $help\n\t  \n" if $debug;

# Subrutine code section
sub getJobById {
	my $id = shift;
	my @jobs = @{ shift() };
	
	foreach (@jobs) {
		my %job = %{$_};
		return %job if $job{id} == $id;
	}
}

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
			#printJob($jobs[-1]) if $debug;
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
		#printJob($jobs[-1]) if $debug;
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

sub createBoxesCSVFormat1 {
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
			print CSVFILE $job_box{id},",",$job_box{name},",",scalar(@childs_id),",\"",join(', ', @childs_id),"\",\"",join(', ', @childs_name),"\"\n";
		}
	}
	
	close CSVFILE;
}

#id name type box_name command machine owner permission date_condition days_of_week start_times condition description std_out_file std_err_file alarm_if_fail
sub createBoxesCSV {
	my @jobs = @{ shift() };
	my $csvFile = shift;
	
	open CSVFILE, ">$csvFile" or die "Cannot create CSV file $csvFile. $!";
	
	print CSVFILE "box id, box name, childs id, childs name, command, machine, owner, permission, date_condition, days_of_week, start_times, condition, description, std_out_file, std_err_file, alarm_if_fail\n";
	foreach (@jobs) {
		my %job_box = %{$_};
		# If it is a box, take its childs
		if( $job_box{type} eq $JOB_TYPES{b} ) {
			my $childs_rows = '';
			my $childs_count = 0;
			foreach (@jobs) {
				my %job_child = %{$_};
				if( $job_child{box_name} eq $job_box{name}) {
					$childs_rows .= sprintf(",,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n", 
									$job_child{id},$job_child{name},exists($job_child{command})?$job_child{command}:' ', 
									exists($job_child{machine})?$job_child{machine}:' ',
									exists($job_child{owner})?$job_child{owner}:' ',
									exists($job_child{permission})?$job_child{permission}:' ',
									exists($job_child{date_condition})?$job_child{date_condition}:' ',
									exists($job_child{days_of_week})?$job_child{days_of_week}:' ',
									exists($job_child{start_times})?$job_child{start_times}:' ',
									exists($job_child{condition})?$job_child{condition}:' ',
									exists($job_child{description})?$job_child{description}:' ',
									exists($job_child{std_out_file})?$job_child{std_out_file}:' ',
									exists($job_child{std_err_file})?$job_child{std_err_file}:' ',
									exists($job_child{alarm_if_fail})?$job_child{alarm_if_fail}:' ');
					$childs_count++;
				}
			}
			print CSVFILE "$job_box{id},$job_box{name},$childs_count Jobs,".
						",", exists($job_box{command})?$job_box{command}:' ',
						",", exists($job_box{machine})?$job_box{machine}:' ',
						",", exists($job_box{owner})?$job_box{owner}:' ',
						",", exists($job_box{permission})?$job_box{permission}:' ',
						",", exists($job_box{date_condition})?$job_box{date_condition}:' ',
						",", exists($job_box{days_of_week})?$job_box{days_of_week}:' ',
						",", exists($job_box{start_times})?$job_box{start_times}:' ',
						",", exists($job_box{condition})?$job_box{condition}:' ',
						",", exists($job_box{description})?$job_box{description}:' ',
						",", exists($job_box{std_out_file})?$job_box{std_out_file}:' ',
						",", exists($job_box{std_err_file})?$job_box{std_err_file}:' ',
						",", exists($job_box{alarm_if_fail})?$job_box{alarm_if_fail}:' ',
						"\n";
			print CSVFILE $childs_rows;
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

sub getSequence {
	my @jobs = @{ shift() };
	my @sequence = @{ shift() };
	my $lastone = 1;
	
	my $lastInSequence = $sequence[-1];
	my %lastJobInSequence = getJobById($lastInSequence, \@jobs);
	$lastJobInSequence{condition} =~ /[s|d|f]\((.*?)\)/;
	my $nextInSequence = $1;
	print "Job id: $lastInSequence \nCondition: $lastJobInSequence{condition} \nNext Job Name: $nextInSequence\n" if $debug;
	
	my $i = 0;
	while( $jobs[$i] or ! $lastone ) {
		my %job = %{$jobs[$i]};
		$i++;
		next if $job{id} == $lastInSequence;
		if( $job{name} eq $nextInSequence ) {
			print "Job $nextInSequence found with id $job{id}\n" if $debug;
			push @sequence, $job{id};
			$lastone = 0;
			last;
		}
	}
	
	if( ! $lastone ) {
		print "Getting next job in sequence for Job with id $sequence[-1]\n" if $debug;
		return getSequence(\@jobs, \@sequence);
	} else {
		print "No more jobs found in this sequence. Finishing it.\n" if $debug;
		return @sequence;
	}
}

sub createSequenceCSV {
	
	my @jobs = @{ shift() };
	my $csvFile = shift;
	
	open CSVFILE, ">$csvFile" or die "Cannot create CSV file $csvFile. $!";
	
	my $secId = 1;
	foreach (@jobs) {
		my %job = %{$_};
		
		if( $job{condition} ) {
			my @sequence = ( $job{id} );
			print "Getting sequence for Job with id $sequence[-1] and condition: $job{condition}\n" if $debug;
			@sequence = getSequence(\@jobs, \@sequence);
			print CSVFILE "Sequence #$secId:,\"", join(',', @sequence), "\"\n";
			print "Sequence #$secId:,\"", join(',', @sequence), "\"\n" if $debug;
			$secId++;
		}
	}
	
	print "Total of ",$secId-1," sequences found\n" if $verbose;
	
	close CSVFILE;
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
		my $queryCount = scalar @jobs_search;
		my $total = scalar @jobs;
		my $percentage = sprintf("%.2f",($queryCount / $total) * 100);
		print "Found $queryCount of $total Jobs ($percentage%)\n";
	} else {
		createGeneralCSV(\@jobs_search, $outFile) if @jobs_search;
	}
}
createSequenceCSV(\@jobs, $outFile) if $sequence;

# Documentation pod section

__END__

=head1 NAME

ajp.pl - AJP (Autosys Jobs Parser) will receive a list of Autosys Jobs in JIL format and will create several documents with useful and easy to understand information. 

=head1 SYNOPSIS

ajp.pl [--help or -h] [--verbose] [--debug or -d] [--jobs=filename or -j filename] [--output=filename or -o filename] [--general or -g] [--boxes or -b] [--print_jobs or -p] [--query=query or -q query] [--count=query or -c query] [--list_fields or -l] [--sequence or -s] [--forecast=filename or -f filename]

 Options:
   --help    or -h                         Brief help message. For more information enter: perldoc ajp.pl
   --verbose or -v                         Provide more information. 
   --debug   or -d                         Provide more information than verbose. Useful for debugging.
   --jobs=filename   or -j filename        Input file with the jobs definition in JIL format. By default the filename is 'alljobs.jil'.
   --output=filename or -o filename        Output file with the results of the actions requested. By default is the standard output.
   --general or -g                         Process all the jobs and create a CSV file with all the jobs and their information.
   --boxes   or -b                         Create a CSV file with all the boxes and childs of each box.
   --print_jobs      or -p                 Process all the jobs anc create a human readable file with all the jobs and theis information.
   --query=query     or -q query           Execute a query to all the jobs and create a CSV file the results. For more information enter: perldoc ajp.pl
   --count=query     or -c query           Execute a query to all the jobs and return the amount of jobs that satisfay the query. And, print the total of jobs too.
   --list_fields     or -l                 List all the possible fields of a job. Useful to create a query.
   --sequence        or -s                 Process all the jobs and get the sequences of execution.

For more information enter: perldoc ajp.pl

=head1 OPTIONS

=over 8

=item B<--help> or B<-h>

Print a brief help message and exits.

=item B<--verbose>

Print more information, useful for debugging but not as verbose as --debug option.

The verbose output is sent to the Standar Error so you may send the verbose to a file using this at the end of the command: 2>delete.me

=item B<--debug>

Print more information than verbose. Useful for debugging.

=item B<--jobs> or B<-j>

Input file with the jobs definition in JIL format. By default the filename is 'alljobs.jil'.

The file will be soemthing like this:

/* ----------------- BASIS_WEEKLY ----------------- */ 

insert_job: BASIS_WEEKLY   job_type: b 
owner: bkpbtch@BKGLOBAL
permission: gx,wx,mx
date_conditions: 1
days_of_week: su
start_times: "18:30"
description: "BASIS_WEEKLY"
alarm_if_fail: 0


 /* ----------------- SAO_SAP_TEMSE_CLEANUP ----------------- */ 

 insert_job: SAO_SAP_TEMSE_CLEANUP   job_type: c 
 box_name: BASIS_WEEKLY
 command: auto_r3v45 -C BKAUTOSYS audit 3 job SAO_SAP_TEMSE_CLEANUP
 machine: bkpcis
 owner: bkpbtch@BKGLOBAL
 permission: gx,wx,mx
 description: "SYSTEM TEMSE PURGE"
 alarm_if_fail: 1

=item B<--output> or B<-o>

Output file with the results of the actions requested. Usualy the output will be a CSV file except for the --print_jobs option that will print all the jobs in a human readable format.

By default is the standard output so you can also send the results to a file using: ajp.pl -g > result.csv

=item B<--general> or B<-g>

Process all the jobs and create a CSV file with all the jobs and their information.

The CSV will have the following fields or columns: id name type box_name command machine owner permission date_condition days_of_week start_times condition description std_out_file std_err_file and alarm_if_fail

You can list all the fields that the CSV will have with the command: ajp.pl -l

=item B<--boxes> or B<-b>

Create a CSV file with all the boxes and childs of each box. The fields of the CSV will be: box id, box name, childs count, childs id and childs name

You may also get the list of boxes (with no childs) using the option --query="job_type=Box"

=item B<--print_jobs> or B<-p>

Process all the jobs anc create a human readable file with all the jobs and theis information.

For every job the same fields will be displayed, even if that field is empty. An example of the output file is:

Information for Job 3029
	Job ID: 3029
	Job Name: FKDI_CITI_APAC_ACT
	Job Type: Child
	Job Box Name: 
	Job Command: auto_r3v45 -C BKAUTOSYS audit 3 job FKDI_CITI_APAC_ACT
	Job Machine bkpcis
	Job Owner: bkpbtch@BKGLOBAL
	Job Permission: "gx,wx,mx"
	Job Date Condition: 1
	Job Days of Week: "mo,tu,we,th,fr"
	Job Start Times: 
	Job Condition: 
	Job Description: "Move file from FTP server to SAP server"
	Job Standard Out File: 
	Job Standard Error File: 
	Job Alarm if Fails: 1

=item B<--query> or B<-q>

Execute a query to all the jobs and create a CSV file the results. The query will be a regular expression, so knowledge of regex is required to do the query.

For more information review the section QUERY SYNTAX below.

=item B<--count> or B<-c>

Same as the option --query but instead of return the results of the query will return the amount of jobs that satisfay the query. 

Also will print the total of jobs as well as the percentage of jobs results of the query.

=item B<--list_fields> or B<-l>

List all the fields of a job. Useful to create a query and to know the fields in the CSV file.

=item B<--sequence> or B<-s>

Process all the jobs and get the sequences of execution.

=item B<--forecast=filename> or B<-f filename>

Read the forcast file with the execution of jobs in a period of time and create a CSV file them and merge it with the information from the JIL file.

=back

=head1 QUERY SYNTAX

=over 8

=item B<Syntax>: 
   
fieldname=value[,values]*[&fielname2=value[,values]]*

The values will be regular expresions so will be different the queries "id=1", "id=^1" and "id=^1$"
   
=item B<Examples>:
   
"id=^1$" List the first job, the one with id=1. If instead of this you use "id=1", this query will return all the jobs where the id has a number 1.
 
"id=^2$,^4$,^234$" List the jobs with id 2, 4 and 234

"job_type=Child" List all the child jobs. Instead of use c, b or f for the job_type field, you need to use: Child, Box and 'File watcher'
 
"start_times=^06,^07&machine=bkpcis" List all the jobs that will start execution during the 6:00 AM to 7:59 AM and are in the machine bkpcis.

=back

=head1 DESCRIPTION

B<This program> This script will receive a list of Autosys Jobs in JIL format and will create several documents with useful and easy to understand information..

B<Author>: "Johandry Amador" < Johandry.Amador@softtek.com >

=cut

