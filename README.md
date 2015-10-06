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

Documentation:
* slurm-drmaa: http://apps.man.poznan.pl/trac/slurm-drmaa

```
# start at home
cd

# make the user able to restart services
sudo visudo

# add the lines (without comment sign and replacing the variables with values):
#$GA_USER ALL=(ALL) ALL
#$GA_USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl
#$GA_USER ALL=(ALL) NOPASSWD: /usr/bin/journalctl
# and exit

# install system libraries, ftp and sql
sudo yum install \
  zlib-devel.x86_64 libxml2-devel.x86_64 libstdc++-devel.x86_64 \
  tmux tree most \
  httpd mod_ldap mod_xsendfile mod_ssl \
  postgresql-server \
  proftpd proftpd-postgresql proftpd-utils proftpd-ldap proftpd-devel

# install slurm-drmaa
curl -# http://apps.man.poznan.pl/trac/slurm-drmaa/downloads/9 | tar xz
SLURMLIB=$(which srun)
SLURMLIB=${SLURMLIB%/bin/srun}
export LD_LIBRARY_PATH="$SLURMLIB:$LD_LIBRARY_PATH"
cd slurm-drmaa-1.0.7
./configure #CFLAGS="-g -O0"
make
sudo make install
cd

# backup config files
f="/etc/httpd/conf/httpd.conf \
  /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/postgresql.conf \
  /etc/slurm_drmaa.conf /etc/proftpd.conf"
for fi in $f ; do sudo cp $f ${f}.original ; done

# test slurm drmaa
export DRMAA_LIBRARY_PATH=/usr/local/lib/libdrmaa.so
echo 'echo "Test executed on host $(hostname) by user $USER"' > test.drmaa
drmaa-run bash test.drmaa

# install galaxy-admin
git clone https://github.com/mpg-age-bioinformatics/galaxy-admin
cp galaxy-admin/credentials.example galaxy-admin/credentials
```

Modify variables/credentials in `galaxy-admin/credentials`.

```
# source and export credentials for installation process
source galaxy-admin/credentials

# install galaxy server
curl https://codeload.github.com/galaxyproject/galaxy/tar.gz/v$GA_VERSION | tar xz
```

## Configuration

```
# setup environment
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

# configure files
galaxy-admin/configure

# install system configuration
galaxy-admin/update server
galaxy-admin/update system

# test
proftpd --config galaxy-admin/system.configured/proftpd.conf -t

# configure sql
sudo postgresql-setup initdb
sudo -u postgres bash -c "cd; psql << HERE
CREATE USER $GA_SQLUSER PASSWORD '$GA_SQLKEY';
ALTER ROLE $GA_SQLUSER with password '$GA_SQLKEY';
CREATE DATABASE $GA_SQLDB WITH OWNER = $GA_SQLUSER;
HERE
"

# start galaxy
sudo systemctl enable galaxyd.service
sudo systemctl start galaxyd.service
tail -f galaxy-$GA_VERSION/paster.log
# until message 'serving on http://...'

# backup database
pg_dumpall -U postgres > backup.postgresql_empty_migrated
```

## Internal

* `Admin > Data > Manage quotas`: Add Quotas (e.g. Default 300GB [default for registered], 
Admin unlimited, Extended 1TB, ...)

* `Admin > Tool sheds > Search and browse tool sheds`: Install tools

    *SEQ:Quality*
    * toolshed.g2.bx.psu.edu/repos/devteam/fastqc
    * toolshed.g2.bx.psu.edu/repos/devteam/fastx_trimmer
    * toolshed.g2.bx.psu.edu/repos/jtilman/flexbar
    * toolshed.g2.bx.psu.edu/repos/devteam/fastq_trimmer_by_quality
    * toolshed.g2.bx.psu.edu/repos/devteam/fastx_clipper
    
    *SEQ:Align*
    * toolshed.g2.bx.psu.edu/repos/devteam/bowtie2
    * toolshed.g2.bx.psu.edu/repos/devteam/tophat2
    * toolshed.g2.bx.psu.edu/repos/devteam/bwa_wrappers
    
    *SEQ:Align:Picard*
    * toolshed.g2.bx.psu.edu/repos/devteam/picard

    *SEQ:Align:Other*
    * toolshed.g2.bx.psu.edu/repos/devteam/sam_bitwise_flag_filter
    * toolshed.g2.bx.psu.edu/repos/devteam/sam_to_bam
    * toolshed.g2.bx.psu.edu/repos/devteam/sam_merge
    * toolshed.g2.bx.psu.edu/repos/devteam/samtools_flagstat
    * toolshed.g2.bx.psu.edu/repos/devteam/depth_of_coverage/gatk_depth_of_coverage/0.0.2

    *SEQ:Align:Bedtools*
    * toolshed.g2.bx.psu.edu/repos/iuc/bedtools
    * (toolshed.g2.bx.psu.edu/repos/aaronquinlan/bedtools)
    
    *SEQ:Snp*
    * toolshed.g2.bx.psu.edu/repos/devteam/variant_select
    * toolshed.g2.bx.psu.edu/repos/iuc/snpeff
    * toolshed.g2.bx.psu.edu/repos/devteam/realigner_target_creator
    * toolshed.g2.bx.psu.edu/repos/devteam/indel_realigner
    * toolshed.g2.bx.psu.edu/repos/devteam/unified_genotyper
    * toolshed.g2.bx.psu.edu/repos/gregory-minevich/snp_mapping_using_wgs
    
    *Seq:DEG*
    * toolshed.g2.bx.psu.edu/repos/devteam/cufflinks
    * toolshed.g2.bx.psu.edu/repos/devteam/cuffmerge
    * toolshed.g2.bx.psu.edu/repos/devteam/cuffcompare
    * toolshed.g2.bx.psu.edu/repos/devteam/cuffdiff
    
    *Convert Formats*
    * toolshed.g2.bx.psu.edu/repos/devteam/fastq_groomer
    
    *Text Manipulation*
    * toolshed.g2.bx.psu.edu/repos/devteam/column_maker
    
    *Workflows*
    * [Cloud Map](https://usegalaxy.org/u/gm2123/w/cloudmap-hawaiian-and-variant-discovery-mapping-on-hawaiian-mapped-samples-and-variant-calling-workflow-2-7-2014) ([Guide](https://usegalaxy.org/u/gm2123/p/cloudmap))
    * RNA Seq

* `Admin > Data > Manage data libraries`: Import (link!) genomes .fa, .gtf files.  
    Create a new library called `Genomes`  
    Create a subfolder for each genome (e.g. `C. elegans`)  
    Import each file into the respective folder with correct file format:  
    * *Upload option*: Upload files from filesystem paths
    * *File format*: gtf/fasta
    * *Copy data into Galaxy?*: Link to files ...
    * File examples (from Ensembl genome builds):

        ```
# TruSeqAdapters Fastas
/beegfs/common/genomes/adapters/All.fasta
# Genome GTFs
/beegfs/common/genomes/caenorhabditis_elegans/WBcel235_81/WBcel235.81.gtf
/beegfs/common/genomes/drosophila_melanogaster/BDGP6_81/BDGP6.81.gtf
/beegfs/common/genomes/mus_musculus/GRCm38_81/GRCm38.81.gtf
/beegfs/common/genomes/homo_sapiens/GRCh38_81/GRCh38.81.gtf
# Genome Toplevel DNA Fastas
/beegfs/common/genomes/caenorhabditis_elegans/WBcel235_81/WBcel235.dna.toplevel.fa
/beegfs/common/genomes/drosophila_melanogaster/BDGP6_81/BDGP6.dna.toplevel.fa
/beegfs/common/genomes/mus_musculus/GRCm38_81/GRCm38.dna.toplevel.fa
/beegfs/common/genomes/homo_sapiens/GRCh38_81/GRCh38.dna.toplevel.fa
```

## Tool Configuration Notes

*toolshed.g2.bx.psu.edu/repos/pcingola/snpeff/snpEff/1.0*

Modify paths in xml files at `shed_tools/toolshed.g2.bx.psu.edu/repos/pcingola/snpeff/c052639fa666/snpeff/snpEff_2_1a/snpEff_2_1a/galaxy/`, use `$SNPEFF_JAR_PATH` as reference.

## Maintenance: PostgreSQL

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
