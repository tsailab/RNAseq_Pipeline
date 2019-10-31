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
### Prepare Design File (Run NGSclean) 
###
touch prep-design-file.sh
echo "cd ${cleanDir}" >> prep-design-file.sh
echo "ml Python/3.6.6-foss-2018b" >>  prep-design-file.sh
echo "python ${NGScleanDir}/generate_design_file.py -f" \
    >> prep-design-file.sh
echo -n " ${fastqDir} -d RNAseq_design.txt" \
    >> prep-design-file.sh
if [[ ${isPaired} -eq 1 ]]; then
    echo -n " -p" >> prep-design-file.sh  # space before -p
fi
