# SeqTrimBB
https://github.com/rafnunser/seqtrimbb

#### DESCRIPTION:

SeqTrimBB is a customizable pre-processing software for NGS (Next Generation Sequencing) data. It uses BBtools, a versatile software suite, as pre-processing engine. It is specially suited for Illumina datasets, although it could be easyly adapted to any other sequencing technology.
 
#### FEATURES:

* SeqTrimBB is very flexible since it's architecture is based on plugins. 
* Each plugin adress a specific issue known to affect subsequent analysis.
* You can add new plugins if needed.
* SeqTrimBB includes preset pre-processing workflows in form of templates.
* You cand add new templates for specific experimental designs or samples. And almost all cleaning parameters can be modified.
* You can pipe pre-proccesed reads directly to an external tool. Specially suited to map or assemble reads.

##### Default templates for genomics & transcriptomics are provided
___
**genomics.txt**: cleans genomics data from Illumina's sequencers.
**genomics_user.txt**: cleans genomics data from Illumina's sequencers, also allows to filter out reads matching any entry in the user contaminant database.
**transcriptomics.txt**: cleans transcriptomics data from Illumina's sequencers.
**transcritomics_user.txt**: cleans transcriptomics data from Illumina's sequencers, also allows to filter out reads matching any entry in the user contaminant database.
**genomics_mate_pairs.txt**: first search and filter true mate pair reads, then proceeds to a generic pre-processing workflow.
  
##### You can define your own templates using a combination of available plugins
___
**PluginAdapters**: trims adapters using a predefined database of adapters, or one provided by the user (a fasta file with adapters sequences inside).
**PluginQuality**: remove low quality fragments from reads.
**PluginFindPolyAt**: trims polyA and polyT from reads.
**PluginLowComplexity**: filter out sequences with low complexity regions.
**PluginVectors**: remove vectors from sequences using a predefined database or one provided by the user (a fasta file with vectors sequences inside).
**PluginContaminants**: removes contaminants reads. It uses a core database, but it can be expanded with user provided ones.
**PluginUserFilter**: filter out reads matching any entry in the user provided database, saving them in a separate file.
**PluginMatePairs**: search and filter true mate pairs reads.

### SYNOPSIS:

Once installed, SeqTrimBB is very easy to use:
  
To **clean** reads using a **predefined template** with a **FASTQ file** using **4 cpus**:

  `seqtrimbb -t genomics.txt -Q input_file_in_FASTQ -w 4`
  
To perform an analisys using a **predefined template** with a **FASTA file** with **QUAL file**:
  
  `seqtrimbb -t genomics.txt -Q input_file_in_FASTA -q input_file_in_QUAL`

To clean **FASTQ files**, with **paired-end** reads in **two files**:

  `seqtrimbb -t genomics.txt -Q p1.fastq,p2.fastq` 

To add a **piped call to an external tool**:

  `seqtrimbb -t genomics.txt -Q input_file_in_FASTQ -E "external_tool_cmd"`
  
To **modify** cleaning parameters directly from your call to SeqTrimBB, use **--overwrite_params** option. To modify more than one parameter use ";" as separator. For example, to change minimal read length to 100 bases:

  `seqtrimbb -t genomics.txt -Q p1.fastq,p2.fastq --overwrite_params "minlength=100"`

To get **additional help** and list of available templates and databases:

  `seqtrimbb -h`
  
To **avoid** databases's checking (and update) add **-c** option to your call.
  
##### TEMPLATE MODIFICATIONS
___

You can modify any template to fit your workflow. To do this, you only need to copy one of the templates and edit it with a text editor, or you can also use as template a modified used_params.txt file that was produced by a previous SeqTrimBB execution, or simply use --overwrite_params to overwrite or add new parameters (changes won't be permanent).
  
Eg.: If you want to change minimal read length to 100 bases, do this:

1. Copy the template file you wish to customize and name it modified_template.txt.
2. Edit modified_template with a text editor. Adding a line like thids: 
minlength=100
3. Launch SeqTrimBB with modified_template.txt file instead of a default template:

  `seqtrimbb -t modified_template.txt -Q input_file_in_FASTQ`

4. You can also launch SeqTrimBB with the original template file overwriting minlength parameter:

  `seqtrimbb -t original_template.txt -Q input_file_in_FASTQ --overwrite_params "minlength=100"`

The same way you can modify any of the parameters. You can find all parameters and their description in any used_params.txt file generated by a previous SeqTrimBB execution. Parameters not especified in a template are automatically set to their default value at execution time.

**NOTE**: The only mandatory parameter is the plugin_list one.

##### Goblal Parameters (In addition to input options)

* sample_species: species of the sample to process. Eg.: Homo sapiens.

### PLUGINS
___
This section includes each plugin provided with SeqTrimBB and its parameters.

##### PluginAdapters

This plugin trims sequencing adapters using a predefined database of adapters, or one provided by the user.

###### Parameters
* adapters_db: sequences of sequencing adapters to use in trimming. Fasta file including them, or folder including multiple Fasta files.
* adapters_3_kmer_size(k): kmer size to use in adapters trimming. Integer.
* adapters_3_min_external_kmer_size(mink): minimal kmer size to use in reads tips in adapters trimming. Integer.
* adapters_3_max_mismatches (hdist): max number of mismatches in adapters trimming.
* adapters_5_kmer_size(k): kmer size to use in adapters trimming. Integer.
* adapters_5_min_external_kmer_size(mink): minimal kmer size to use in reads tips in adapters trimming. Integer.
* adapters_5_max_mismatches (hdist): max number of mismatches in adapters trimming.
* adapters_trimming_position(rref/lref): trims adapters from right, left or both reads tips. Use right, left or both (default).
* adapters_merging_pairs_trimming(tbo tpe): if true trims adapters of paired reads using merging reads methods. Use true or false.

Trimming parameters for 5' trimming are set based on 3' trimming parameters value. However you can give then a specific value using a custom template or --overwrite_params option.

##### PluginQuality

This plugin trims low quality fragments from reads. Keeps the largest reads fragment with mean quality equal or above a quality threshold.

###### Parameters
* quality_threshold(trimq): quality threshold to be applied (Phred quality score). Integer.
* quality_trimming_position(qtrim): trims low quality fragment from right, left or boths reads tips. Use right, left or both.

##### PluginContaminants

This plugin removes contaminants reads using a database composed of contaminants Fasta files.

###### Parameters

* contaminants_dbs: databases to use in decontamination. You can use internal databases (databases name), an external Fasta file (full path to the file), or a external folder containing multiple Fasta files (full path to the folder).
* contaminants_minratio(minratio): minimal ratio of contaminants kmers in a read to be removed. Percentage expressed as a decimal.
* contaminants_decontamination_mode: regular or excluding. Regular just removes contaminants reads using the whole database, excluding avoids removing non contaminant reads if the sample species or one with the same genus is in the database. Use regular, excluding genus (conservative) or excluding species (maximal sensitivity).

##### PluginLowComplexity

This plugin removes reads with low complexity regions using a complexity threshold.

###### Parameters

* complexity_threshold(entropy): threshold to be applied. Complexity is calculated using the counts of unique short kmers that occur in a window, such that the more unique kmers occur within the window - and the more even the distribution of counts - the closer the value approaches 1. Complexity_threshold = 0.01 for example will only filter homopolymers' 

##### PluginUserFilter

This plugin filters out reads matching any entry in the user provided database, saving them in a separate file.

###### Parameters

* user_filter_db: database to use in filtering. You can use internal databases (databases name), an external Fasta file (full path to the file), or a folder containing an external database in Fasta format (full path to the folder).
* user_filter_minratio: minimal ratio of sequence of interest in a read to be filter out. Percentage expressed as a decimal.
* user_filter_species: list of species (entries) of interest in the database (comma separated) to be filter out. if empty, this plugin will save all the reads matching any entry (species) in the database.

##### PluginPolyAt

This plugin trims polyA and polyT tails from RNA-seq reads.

###### Parameters

* polyat_min_size(k): minimal size of a polyAT to be trimmed. Integer.

##### PluginVectors

This plugin removes vectors from reads. Filter out vectors reads and trims vectors fragments from samples reads.

###### Parameters
* vectors_db: sequences of vectors to filter and trim. Fasta file including them, or folder including multiple Fasta files.
* vectors_kmer_size(k): kmer size to use in vectors trimming. Integer.
* adapters_min_external_kmer_size(mink): minimal kmer size to use in reads tips in vectors trimming. Integer.
* vectors_max_mismatches (hdist): max number of mismatches in vectors trimming.
* vectors_trimming_position(rref/lref): trims vectors from right, left or both reads tips. Use right, left or both (default).
* vectors_merging_pairs_trimming(tbo tpe): if true trims vectors of paired reads using merging reads methods. Use true or false.
* vectors_minratio(minratio): minimal ratio of vectors sequence in a read to be filter out. Percentage expressed as a decimal.

##### PluginMatePairs

This plugin searches for true mate pair reads and filter them.

###### Parameters

* linker_literal_seq: literal sequence of the linker used in samples sequencing.


### REQUIREMENTS:

* Ruby 1.9.3-p327 or greater
* BBmap 37.17 or greater
* Fastqc

### INSTALL:
  
#### Install BBtools (BBmap) 

**Download** BBtools from the official repository:

https://sourceforge.net/projects/bbmap/

Decompress it:

`tar xvzf BBMap_37.68.tar.gz`

Export the path of the shellscripts to your enviroment or set the enviroment variable +BBPATH+. Eg.:

BBMap decompressed at /var:

  `export BBPATH=/var/BBMap`
  
Be sure that this environment variable is always loaded before SeqTrimBB execution (Eg.: add it to /etc/profile.local).

#### Install SeqTrimBB

SeqtrimBB is very easy to install. It is distributed as a **ruby gem**:

  `gem install seqtrimbb`
  
This will install SeqTrimBB and all the required gems.

#### Install SeqTrimBB's core databases

To install SeqTrimBB's core databases:

  `seqtrimbb -i`

To update SeqTrimBB's core databases:

  `seqtrimbb -i update`

Databases installation uses Subversion to download files from databases repository. If your system does not support svn, you can clone databases repository (https://github.com/rafnunser/seqtrimbb-databases.git). By default cloned files must be placed inside SeqTrimBB's root, in a folder called 'DB'.

### Database modifications

Databases will be installed nearby SeqtrimBB by default, but you can override this location by setting the environment variable +BBDB+. Eg.:

Database installed at /var:
  `export BBDB=/var/DB`

Be sure that this environment variable is always loaded before SeqTrimBB execution (Eg.: add it to /etc/profile.local).

Included databases will be usefull for a lot of people, but if you prefer, you can modify them, or add more elements to be search against your reads. You only need to drop new fasta files to each respective directory in DB/fastas, or even make new directories with fasta files inside. For a proper use, name the fasta files with the species name (eg. Homo_sapiens.fasta or Homo_sapiens_chr1.fasta) if it is possible. Each directory with fasta files will be used as a database: DB/fastas/vectors to add more vectors, DB/fastas/contaminants to add more contaminants, etc...
Once the databases has been modified, will be updated in the next SeqtTrimBB execution.


## LICENSE:

(The MIT License)

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
