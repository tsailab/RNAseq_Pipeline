###
### This script will create all directories and scripts used in part 1 of the
### RNAseq analysis
###
### USAGE:
###  $1  root directory for project
###  $2  Paired end single end reads
###        "pe" for paired-end reads
###        "se" for single-end reads
###


###
### Parameter check
###

if [ ! -z "$1" ]
then
    rootDir=$1
    echo $rootDir
else
    echo "You have not entered the correct number of parameters"
    exit 0
fi


if [ ! -z "$2" ]
then
    if [ "$2" = "pe" ]
    then
        isPaired=1
    elif [ "$2" = "se" ]
    then
        isPaired=0
    else
        echo "paired vs single end read param incorrect format."
        echo "Use either 'pe' for paired-end reads or 'se' for single-end reads"
        exit 0
    fi
else
    echo "You have not entered the correct number of parameters"
    exit 0
fi


###
### Directories
###
rootDir=$1
fastqDir=${rootDir}/fastq              # project root
cleanDir=${rootDir}/clean              # fastq files go here
mapDir=${rootDir}/map                  # mapping output
resultsDir=${rootDir}/resultsForPt2    # results used for part 2 are copied here
NGScleanDir=${rootDir}/NGSclean        # NGSclean git repo gets cloned here
scriptsDir=${rootDir}/scripts          # scripts get written here


###
### Make directories
###
mkdir -p $rootDir
mkdir $fastqDir
mkdir $cleanDir
mkdir $mapDir
mkdir $resultsDir
mkdir $scriptsDir


###
### Clone NGS clean dir
###
git clone https://github.com/tsailab/NGSclean.git $NGScleanDir


###
### 2.1 Prepare Design File (Run NGSclean) 
###
designFile="${scriptsDir}/01-prep-design-file.sh"
touch "${designFile}"
printf "cd ${cleanDir}\n" >> "${designFile}"
printf "ml Python/3.6.6-foss-2018b\n" >> "${designFile}"
printf "python ${NGScleanDir}/generate_design_file.py -f" \
    >> "${designFile}"
printf " ${fastqDir} -d RNAseq_design.txt" \
    >> "${designFile}"
if [[ ${isPaired} -eq 1 ]]; then
    printf " -p\n" >> "${designFile}"  # space before -p
fi


###
### 2.2 Trim and Clean
###

# Sapelo 2 Settings
trimmoFull="usr/local/apps/eb/Trimmomatic/0.36-Java-1.8.0_144/trimmomatic-0.36.jar"
starFull="/usr/local/apps/eb/STAR/2.5.3a-foss-2016b/bin/STAR"
adaptor="usr/local/apps/eb/Trimmomatic/0.36-Java-1.8.0_144/adapters/TruSeq3-PE.fa"
trimmo_module="Java/1.8.0_144"
star_module="STAR/2.5.3a-foss-2016b"

# Run the pipeline
trimCleanFile="${scriptsDir}/02-trim-and-clean.sh"
printf "cd ${cleanDir}\n" >> ${trimCleanFile}
printf "ml Python/3.6.6-foss-2018b" >> ${trimCleanFile}
printf "${NGScleanDir}/trim_and_clean.py -d RNAseq_design.txt" \
    >> ${trimCleanFile}
printf " -t 8 -s merge --run_trimmomatic ${trimmoFull}" \
    >> ${trimCleanFile}
printf " --load_trimmo_module ${trimmo_module}" \
    >> ${trimCleanFile}
printf " --adaptor ${adaptor}" \
    >> ${trimCleanFile}
printf " --run_star ${starFull} --load_star_module ${star_module}\n" \
    >> ${trimCleanFile}

# submit the jobs
echo "" >> ${trimCleanFile}
echo "cd ${cleanWorking}" >> ${trimCleanFile}
echo "chmod 750 Run_RNAseq_design.sh" >> ${trimCleanFile}
echo "./Run_RNAseq_design.sh" >> ${trimCleanFile}















