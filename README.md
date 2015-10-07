# galaxy-admin

## About

This repository contains the documentation and scripts to be used for the
installation of a galaxy webserver instance using the following specifications:

* CentOS 7 Linux
* 4 CPUs, 2 GB RAM
* Linux user to run servers (galaxy, ftp, http), submit
jobs and request LDAP server
* Galaxy host and cluster node share common folder
    * galaxy home
    * software modules
    * genome reference indices
* Module environment for software path management
    * slurm
    * python 2.7.9
* PostgreSQL server with user and database for galaxy
* Apache web server (httpd) with LDAP authentification
* ProFTP server with LDAP authentification

## Installation

Requirements are `git`, `slurm`/`munge`, `sudo` and `sshd`.
Run the installation commands from your home folder.

```
cd
```

### Shell environment

Adjust `~/.bashrc` to load slurm and python `$PATH`, `$LD_LIBRARY_PATH`,
`$PYTHONHOME`, `$PYTHONUSERBASE` and `$PYTHONPATH`.

```
cat >> .bashrc << HERE
# galaxy-admin
source /usr/share/Modules/init/bash
source /software/Modules/modules.rc
module purge
module load slurm
module load slurm_scripts
module load galaxy-python/2.7.9
HERE
source .bashrc
```

### galaxy-admin

Clone the repository from github, and create credentials file.

```
git clone https://github.com/mpg-age-bioinformatics/galaxy-admin
cp galaxy-admin/credentials.example galaxy-admin/credentials
```

Modify the file `credentials` and source it to export variables.

```
source galaxy-admin/credentials
```

Update the server configuration. This prints the configuration values for a check
and creates the folder `galaxy-admin/configured` which contains all updated files
with the `%%GA_*%%%` variables replaced by your credentials.

```
galaxy-admin/configure
```

Adjust the genome reference indices for the aligner `tophat2` and `bowtie` at
`galaxy-admin/configured/server/tool-data/bowtie2_indices.loc`. Register more
tables (e.g. for `bwa`) at `galaxy-admin/configured/server/config/tool_data_table_conf.xml`.

### Sudo

Enable `sudo` for the galaxy linux user.

```
sudo visudo
```

Insert the lines, replace `%%GA_USER%%` with the user id.

```
%%GA_USER%% ALL=(ALL) ALL
%%GA_USER%% ALL=(ALL) NOPASSWD: /usr/bin/systemctl
%%GA_USER%% ALL=(ALL) NOPASSWD: /usr/bin/journalctl
```

### CentOS packages

```
sudo yum install \
  zlib-devel.x86_64 libxml2-devel.x86_64 libstdc++-devel.x86_64 \
  tmux tree most \
  httpd mod_ldap mod_xsendfile mod_ssl \
  postgresql-server \
  proftpd proftpd-postgresql proftpd-utils proftpd-ldap proftpd-devel
```

### Slurm drmaa

Documentation: http://apps.man.poznan.pl/trac/slurm-drmaa

```
curl -# http://apps.man.poznan.pl/trac/slurm-drmaa/downloads/9 | tar xz
SLURMLIB=$(which srun)
SLURMLIB=${SLURMLIB%/bin/srun}
export LD_LIBRARY_PATH="$SLURMLIB:$LD_LIBRARY_PATH"
cd slurm-drmaa-1.0.7
./configure #CFLAGS="-g -O0"
make
sudo make install
cd
```

Now, test the configuration:

```
export DRMAA_LIBRARY_PATH=/usr/local/lib/libdrmaa.so
echo 'echo "Test executed on host $(hostname) by user $USER"' > test.drmaa
drmaa-run bash test.drmaa
```

### PostgreSQL

Initialize and create the database and galaxy sql user.

```
sudo postgresql-setup initdb
sudo -u postgres bash -c "cd; psql << HERE
CREATE USER $GA_SQLUSER PASSWORD '$GA_SQLKEY';
ALTER ROLE $GA_SQLUSER with password '$GA_SQLKEY';
CREATE DATABASE $GA_SQLDB WITH OWNER = $GA_SQLUSER;
HERE
"
```

### ProFTPd

Test the proftpd configuration with your credentials.

```
proftpd --config galaxy-admin/configured/system/proftpd.conf -t
```

### Galaxy server

```
curl https://codeload.github.com/galaxyproject/galaxy/tar.gz/v$GA_VERSION | tar xz
```

### Update configuration

Backup the original system configuration files.

```
f="/etc/httpd/conf/httpd.conf \
  /var/lib/pgsql/data/pg_hba.conf \
  /var/lib/pgsql/data/postgresql.conf \
  /etc/slurm_drmaa.conf /etc/proftpd.conf"
for fi in $f ; do sudo cp $f ${f}.original ; done
```

Now update the system and server configuration.

```
galaxy-admin/update system
galaxy-admin/update server
```

Enable all services and (re)start httpd, proftpd and postgresql.

```
galaxy-admin/update services
```

Start galaxy as service.

```
sudo systemctl start galaxyd
```

### Galaxy server quotas

`Admin > Data > Manage quotas`

* Default [300GB, default for registered]
* Large [3TB]
* Admin [unlimited]

### Galaxy server tools

`Admin > Tools and tool Shed > Search tool shed`

Category *Convert Formats*
* toolshed.g2.bx.psu.edu/repos/devteam/fastq_groomer

Category *Text Manipulation*
* toolshed.g2.bx.psu.edu/repos/devteam/column_maker

Category *SEQ:Quality*
* toolshed.g2.bx.psu.edu/repos/devteam/fastqc
* toolshed.g2.bx.psu.edu/repos/devteam/fastx_trimmer
* toolshed.g2.bx.psu.edu/repos/jtilman/flexbar
* toolshed.g2.bx.psu.edu/repos/devteam/fastq_trimmer_by_quality
* toolshed.g2.bx.psu.edu/repos/devteam/fastx_clipper

Category *SEQ:Align*
* toolshed.g2.bx.psu.edu/repos/devteam/bowtie2
* toolshed.g2.bx.psu.edu/repos/devteam/tophat2
* toolshed.g2.bx.psu.edu/repos/devteam/bwa_wrappers

Category *SEQ:Align:Picard*
* toolshed.g2.bx.psu.edu/repos/devteam/picard

Category *SEQ:Align:Other*
* toolshed.g2.bx.psu.edu/repos/devteam/sam_bitwise_flag_filter
* toolshed.g2.bx.psu.edu/repos/devteam/sam_to_bam
* toolshed.g2.bx.psu.edu/repos/devteam/sam_merge
* toolshed.g2.bx.psu.edu/repos/devteam/samtools_flagstat
* toolshed.g2.bx.psu.edu/repos/devteam/depth_of_coverage/gatk_depth_of_coverage/0.0.2

Category *SEQ:Align:Bedtools*
* toolshed.g2.bx.psu.edu/repos/iuc/bedtools
* (toolshed.g2.bx.psu.edu/repos/aaronquinlan/bedtools)

Category *SEQ:Snp*
* toolshed.g2.bx.psu.edu/repos/devteam/variant_select
* toolshed.g2.bx.psu.edu/repos/iuc/snpeff
* toolshed.g2.bx.psu.edu/repos/devteam/realigner_target_creator
* toolshed.g2.bx.psu.edu/repos/devteam/indel_realigner
* toolshed.g2.bx.psu.edu/repos/devteam/unified_genotyper
* toolshed.g2.bx.psu.edu/repos/gregory-minevich/snp_mapping_using_wgs

Category *Seq:DEG*
* toolshed.g2.bx.psu.edu/repos/devteam/cufflinks
* toolshed.g2.bx.psu.edu/repos/devteam/cuffmerge
* toolshed.g2.bx.psu.edu/repos/devteam/cuffcompare
* toolshed.g2.bx.psu.edu/repos/devteam/cuffdiff

### Galaxy tool configuration notes

*toolshed.g2.bx.psu.edu/repos/pcingola/snpeff/snpEff/1.0*

Modify paths in xml files at `shed_tools/toolshed.g2.bx.psu.edu/repos/pcingola/snpeff/c052639fa666/snpeff/snpEff_2_1a/snpEff_2_1a/galaxy/`.
E.g. create `$SNPEFF_JAR_PATH` as reference for the paths.


### Galaxy workflows

* [Cloud Map](https://usegalaxy.org/u/gm2123/w/cloudmap-hawaiian-and-variant-discovery-mapping-on-hawaiian-mapped-samples-and-variant-calling-workflow-2-7-2014) ([Guide](https://usegalaxy.org/u/gm2123/p/cloudmap))
* RNA Seq

### Galaxy genome references

`Admin > Data > Data libraries`
* Create new library `Genomes`
* `Add datasets`
    * Upload option: `Upload files from filesystem paths`
    * Select format
    * Insert paths (no trailing spaces, new line separated)
    * Copy data into galaxy?: `Link to files without copying into Galaxy`

Example file list:

```
# TruSeqAdapters
# Format: fasta
/beegfs/common/genomes/adapters/All.fasta

# Genome annotations
# Format: gtf
/beegfs/common/genomes/caenorhabditis_elegans/WBcel235_81/WBcel235.81.gtf
/beegfs/common/genomes/drosophila_melanogaster/BDGP6_81/BDGP6.81.gtf
/beegfs/common/genomes/mus_musculus/GRCm38_81/GRCm38.81.gtf
/beegfs/common/genomes/homo_sapiens/GRCh38_81/GRCh38.81.gtf

# Genome DNA sequences
# Format: fasta
/beegfs/common/genomes/caenorhabditis_elegans/WBcel235_81/WBcel235.dna.toplevel.fa
/beegfs/common/genomes/drosophila_melanogaster/BDGP6_81/BDGP6.dna.toplevel.fa
/beegfs/common/genomes/mus_musculus/GRCm38_81/GRCm38.dna.toplevel.fa
/beegfs/common/genomes/homo_sapiens/GRCh38_81/GRCh38.dna.toplevel.fa
```

## Maintenance

### PostgreSQL

Backup initial database, after server started the first time,
check the message `serving on http://...` in the galaxy log file.

```
pg_dumpall -U postgres > backup.postgresql_empty_migrated
```

Reset database:

```
sudo systemctl stop galaxyd.service
pg_dumpall -U postgres > backup.postgresql_XYZ
# pg_restore -U galaxy -U galaxy -d galaxy dump.postgresql
dropdb -U $GA_SQLUSER $GA_SQLDB
sudo -u postgres createdb -O $GA_SQLUSER $GA_SQLDB

sudo systemctl start galaxyd.service
```

Complete reset:

```
sudo systemctl stop postgresql.service
sudo rm -rf /var/lib/pgsql/data /var/lib/pgsql/initdb.log
sudo postgresql-setup initdb
source galaxy-admin/credentials
galaxy-admin/configure
galaxy-admin/update system
sudo -u postgres bash -c "cd; psql << HERE
CREATE USER $GA_SQLUSER PASSWORD '$GA_SQLKEY';
ALTER ROLE $GA_SQLUSER with password '$GA_SQLKEY';
CREATE DATABASE $GA_SQLDB WITH OWNER = $GA_SQLUSER;
HERE
"

sudo systemctl start galaxyd.service
```

## License

Developed by Sven E. Templer at the Max Planck Institute for Biology of Ageing, Cologne, Germany.

http://www.age.mpg.de
http://mpg-age-bioinformatics.github.io

All files in this repository are shared under the following license:

> Copyright (c) 2015 Sven E. Templer
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
> THE SOFTWARE.

See also file `LICENSE`.
