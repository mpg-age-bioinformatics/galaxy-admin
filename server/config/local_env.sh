# %%GA_HOME%%/config/local_env.sh

PYTHONPATH_STORED="$PYTHONPATH"
export TEMP="%%GA_HOME%%/database/tmp:$TEMP"
export SLURM_DRMAA_CONF="/etc/slurm_drmaa.conf"
export DRMAA_LIBRARY_PATH="/usr/local/lib/libdrmaa.so"
export DRMAA_PATH="$DRMAA_LIBRARY_PATH"
export SGE_ROOT="/usr/local/"
export GALAXY_SLURM="1"

source /usr/share/Modules/init/bash
source /software/Modules/modules.rc
module purge
module load slurm
module load galaxy-python/2.7.9
module load Java/1.7.0_79

module load Flexbar/2.5
#export SNPEFF_JAR_PATH="%%GA_PREFIX%%/shed_tools/toolshed.g2.bx.psu.edu/repos/pcingola/snpeff/c052639fa666/snpeff/snpEff_2_1a/snpEff_2_1a"
#export SNPEFF_JAR_PATH="%%GA_HOME%%/tool-depends/snpEff/4.0/iuc/package_snpeff_4_0/792d8f4485fb"

# restore the PYTHONPATH after module calls
[[ -n $PYTHONPATH ]] && PYTHONPATH_STORED="$PYTHONPATH_STORED:$PYTHONPATH"
export PYTHONUSERBASE="$HOME/.local/"
export PYTHONPATH="$PYTHONPATH_STORED"

