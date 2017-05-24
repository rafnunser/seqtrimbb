= seqtrimBB

* http://www.scbi.uma.es/downloads

== DESCRIPTION:

SeqtrimBB is a customizable pre-processing software for NGS (Next Generation Sequencing) biological data. It  uses BBtools, a versatile software suite. It is specially suited for Ilumina datasets, although it could be easyly adapted to any other situation.
 
== FEATURES:

* SeqtrimBB is very flexible since it's architecture is based on plugins.
* SeqtrimBB includes preset pre-processing workflows in form of templates.
* You can add new plugins if needed.
* You cand add new templates for specific experimental designs or samples.
* You can pipe clean reads directly to an external tool. Specially suited to map or assemble reads.

== Default templates for genomics & transcriptomics are provided

<b>genomics.txt</b>:: cleans general genomics data from Illumina's sequencers.
<b>genomics_user.txt</b>:: cleans generals genomics data from Illumina's sequencers, also allows to filter out reads matching any entry in the user contaminant database.
<b>transcriptomics.txt</b>:: cleans transcriptomics data from Illumina's sequencers.
<b>transcritomics_user.txt</b>:: cleans generals transcriptomics data from Illumina's sequencers, also allows to filter out reads matching any entry in the user contaminant database.
<b>genomics_mate_pairs.txt</b>:: First search and filter true mate pair reads, then proceeds to a generic cleaning workflow.
  
== You can define your own templates using a combination of available plugins:

<b>PluginAdapters</b>:: removes AB adapters from sequences using a predefined DB or one provided by the user.
<b>PluginFindPolyAt</b>:: removes polyA and polyT from sequences.
<b>PluginLowComplexity</b>:: filters sequences with low complexity regions
<b>PluginAdapters</b>:: removes Adapters from sequences using a predefined DB or one provided by the user.
<b>PluginVectors</b>:: remove vectors from sequences using a predefined database or one provided by the user.
<b>PluginContaminants</b>:: remove contaminants from sequences or rejects contaminated ones. It uses a core database, but it can be expanded with user provided ones.
<b>PluginUserFilter</b>:: filter sequences matching any entry in the user contaminant database saving them in a separate file.

== SYNOPSIS:

Once installed, SeqtrimBB is very easy to use:
  
To install core databases (it should be done at installation time):

  $> seqtrimbb -i core

There are aditional databases. To list them:

  $> seqtrimbb -i LIST

To perform an analisys using a predefined template with a FASTQ file format using 4 cpus and 8 gb of RAM:

  $> seqtrimbb -t genomics.txt -Q input_file_in_FASTQ -w 4 -m 8G
  
To perform an analisys using a predefined template with a FASTA file format with QUAL file:
  
  $> seqtrimbb -t genomics.txt -Q input_file_in_FASTA -q input_file_in_QUAL

To clean fastq files, with paired-ends reads in two files, using 4 cpus and output:

  $> seqtrimbb -t genomics.txt -Q p1.fastq,p2.fastq -w 4 

To add a piped call to an external tool

  $> seqtrimbb -t genomics.txt -Q input_file_in_FASTQ -E "cat > mockfile.fastq"

To get additional help and list available templates and databases:

  $> seqtrimbb -h
  
== TEMPLATE MODIFICATIONS

You can modify any template to fit your workflow. To do this, you only need to copy one of the templates and edit it with a text editor, also using a modified used_params.txt file that was produced by a previous SeqtrimBB execution as template, or simply use -P to overwrite or add new parameters.
  
Eg.: If you want to change minimal read length to 100 bases, do this:

1-Copy the template file you wish to customize and name it params.txt.
2-Edit params.txt with a text editor
3-Add a line like this:

minlength=100

4- Launch SeqtrimBB with params.txt file instead of a default template:

  $> seqtrimBB -t params.txt -Q input_file_in_FASTA -q input_file_in_QUAL

5- You can also launch SeqTrimBB with the original template file overwriting minlength parameter:

  $> seqtrimbb -t template.txt -Q input_file_in_FASTQ -P minlength=100


The same way you can modify any of the parameters. You can find all parameters and their description in any used_params.txt file generated by a previous SeqtrimBB execution. Parameters not especified in a template are automatically set to their default value at execution time.

<b>NOTE</b>: The only mandatory parameter is the plugin_list one.

== REQUIREMENTS:

* Ruby 1.9.2 or greater
* BBmap 37.17 or greater

== INSTALL:

=== Installing Ruby 1.9

*You can use RVM to install ruby:

Download latest certificates (maybe you don't need them):

  $ curl -O http://curl.haxx.se/ca/cacert.pem 
  $ export CURL_CA_BUNDLE=`pwd`/cacert.pem # add this to your .bashrc or 
equivalent

Install RVM following the directions from this web:

  https://rvm.io/rvm/install
  
Install ruby 1.9.2 (this can take a while):
  
  $ rvm install 1.9.2
  
Set it as the default:

  $ rvm use 1.9.2 --default

=== Install SeqtrimBB

SeqtrimBB is very easy to install. It is distributed as a ruby gem:

  gem install seqtrimBB
  
This will install seqtrimBB and all the required gems.

=== Install and rebuild SeqtrimBB's core databases

SeqtrimBB needs some core databases to work. To install them:

  seqtrimBB -i core
  
You can change default database location by setting the environment variable +BLASTDB+. Refer to SYNOPSIS for an example.

There are aditional databases that can be listed with:

  seqtrimBB -i LIST

=== Database modifications

Included databases will be usefull for a lot of people, but if you prefer, you can modify them, or add more elements to be search against your sequences. 

You only need to drop new fasta files to each respective directory, or even create new directories with new fasta files inside. For a proper use, name the fasta files with species name (eg. Homo_sapiens.fasta or Homo_sapiens_chr1.fasta) if it is possible. Each directory with fasta files will be used as a database:

DB/vectors to add more vectors
DB/contaminants to add more contaminants
etc...

Once the databases has been modified, you will need to reformat them by issuing the following command:

  seqtrimBB -c

Modified databases will be rebuilt.


== CLUSTERED INSTALLATION

To install SeqtrimBB into a cluster, you need to have the software available on all machines. By installing it on a shared location, or installing it on each cluster node. Once installed, you need to create a init_file where your environment is correctly setup (paths, BLASTDB, etc):

  export PATH=/apps/blast+/bin:/apps/cd-hit/bin
  export BLASTDB=/var/DB/formatted
  export SEQTRIMBB_INIT=path_to_init_file
  

And initialize the SEQTRIMBB_INIT environment variable on your main node (from where SeqtrimBB will be initially launched):

  export SEQTRIMBB_INIT=path_to_init_file

If you use any queue system like PBS Pro or Moab/Slurm, be sure to initialize the variables on each submission script. 

<b>NOTE</b>: all nodes on the cluster should use ssh keys to allow SeqtrimBB to launch workers without asking for a password.

== SAMPLE INIT FILES FOR CLUSTERED INSTALLATION:

=== Init file

  $> cat stn_init_env 

  source ~latex/init_env
  source ~ruby19/init_env

  export SEQTRIMBB_INIT=~seqtrimBB/stn_init_env


=== PBS Submission script

  $> cat sample_work.sh 
  
  # 40 distributed workers and 1 GB memory per worker:
  #PBS -l select=40:ncpus=1:mpiprocs=1:mem=1gb
  # request 10 hours of walltime:
  #PBS -l walltime=10:00:00
  # cd to working directory (from where job was submitted)
  cd $PBS_O_WORKDIR

  # create workers file with assigned node names

  cat ${PBS_NODEFILE} > workers

  # init seqtrimBB
  source ~seqtrimBB/init_env

  time seqtrimBB -t paired_ends.txt -Q fastq -w workers -s 10.0.0


Once this submission script is created, you only need to launch it with:

  qsub sample_work.sh

=== MOAB/SLURM submission script

  $> cat sample_work_moab.sh

  #!/bin/bash 
  # @ job_name = STN
  # @ initialdir = .
  # @ output = STN_%j.out
  # @ error = STN_%j.err
  # @ total_tasks = 40
  # @ wall_clock_limit = 10:00:00

  # guardar lista de workers
  sl_get_machine_list > workers

  # init seqtrimBB
  source ~seqtrimBB/init_env

  time seqtrimBB -t paired_ends.txt -Q fastq -w workers -s 10.0.0

Then you only need to submit your job with mnsubmit

  mnsubmit sample_work_moab.sh


== LICENSE:

(The MIT License)

Copyright (c) 2011 Almudena Bocinos & Dario Guerrero

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
