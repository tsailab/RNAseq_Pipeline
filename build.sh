###
### This script will create all directories and scripts used in part 1 of the
### RNAseq analysis
###
### USAGE:
###  $1  root directory for project
###  $2  paired end single end reads
###        POSSIBLE VALUES:
###          "pe" for paired-end reads
###          "se" for single-end reads
###  $3  genome for project
###        POSSIBLE VALUES:
###          "s717" for sPta717 v1.1
###          "ptri" for P. trichocarpa v3.0
###          "pdel" for P. deltoides v2.0
###          "ath" for Arabidopsis thaliana v11


###
### Parameter check
###

# param 1
if [ ! -z "$1" ]
then
    rootDir=$1
    echo $rootDir
else
    echo "   You have not entered the correct number of parameters"
    echo "   Refer to the instructions in the README.md file for more information."
    exit 0
fi

# param 2
if [ ! -z "$2" ]
then
    if [ "$2" = "pe" ]
    then
        isPaired=1
    elif [ "$2" = "se" ]
    then
        isPaired=0
    else
        echo "   Paired vs single end read param incorrect format."
        echo "   Refer to the instructions in the README.md file for more information."
        exit 0
    fi
else
    echo "   You have not entered the correct number of parameters"
    echo "   Refer to the instructions in the README.md file for more information."
    exit 0
fi

# param 3
if [ ! -z "$3" ]
then
    genomeOriDir=/IOBbackup/cjtlab/Database/genome/
    genomeAnnoDir=/IOBbackup/cjtlab/Database/genome_anno/
    if [ "$3" = "s717" ]
    then
        genomeOriDir=${genomeOriDir}s717genome
        genomeAnnoDir=${genomeAnnoDir}sPta717v1
    elif [ "$3" = "ptri" ]
    then
        genomeOriDir=${genomeOriDir}PtiV3_genome
        genomeAnnoDir=${genomeAnnoDir}Ptri_v3
    elif [ "$3" = "pdel" ]
    then
        genomeOriDir=${genomeOriDir}Pdel_genome
        genomeAnnoDir=${genomeAnnoDir}Pdel
    elif [ "$3" = "ath" ]
    then
        genomeOriDir=${genomeOriDir}Araport11_genome
        genomeAnnoDir=${genomeAnnoDir}Araport11
    else
        echo "   Genome annotation parameter is formatted incorrectly."
        echo "   Refer to the instructions in the README.md file for more information."
        exit 0
    fi
else
    echo "   You have not entered the correct number of parameters"
    echo "   Refer to the instructions in the README.md file for more information."
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
genomeDir=${rootDir}/genome            # genome is placed here


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
#git clone https://github.com/tsailab/NGSclean.git $NGScleanDir


###
### Copy genome and annotation
###
#cp -r ${genomeOriDir} ${genomeDir}
#cp ${genomeAnnoDir}/*.gtf ${genomeDir}


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



###
### Mapping
###
mapScript=${scriptsDir}/04map.sh
workingDir=${mapDir}
dataDir=${cleanDir}
genome=${genomeDir}

printf "cd $workingDir\n">>$mapScript
printf "master=\"Shell_master_STAR.sh\"\n">>$mapScript
printf "printf \"#\"\'!\'/bin/bash\"\\\n\">\$master\n">>$mapScript
printf "index=0\n">>$mapScript
printf "for read1 in ${dataDir}/*_clean_1.fq.gz\n">>$mapScript
printf "do\n">>$mapScript
printf "    sample=\${read1%%%%_clean_1.fq.gz}\n">>$mapScript

# if paired end reads
if [ "$isPaired" -eq "1" ]; then
    printf "    read2=\$sample\"_clean_2.fq.gz\"\n">>$mapScript
fi

printf "    sampleshort=\${sample##*/}\n">>$mapScript
printf "    index=\$((\$index+1))\n">>$mapScript
printf "    sh_worker=\"run\"\$index\"_\"\$sampleshort\".sh\"\n">>$mapScript
printf "    printf \"qsub \"\$sh_worker\"\\\n\" >>\$master\n">>$mapScript
printf "    printf \"#\"\'!\'/bin/bash\"\\\n\" >\$sh_worker\n">>$mapScript
printf "    printf \"#PBS -N star_\"\$sampleshort\"\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \"#PBS -q batch\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \"#PBS -l nodes=1:ppn=12:Intel\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \"#PBS -l walltime=12:00:00\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \"#PBS -l mem=30gb\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \"cd \"\$workingDir\"\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \"ml STAR/2.5.3a-foss-2016b \\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \'/usr/local/apps/eb/STAR/2.5.3a-foss-2016b/bin/STAR \\\\\\\'\"\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \' --runThreadN 12 \\\\\\\'\"\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \' --genomeDir \'\$genome\' --readFilesIn \\\\\\\'\"\\\n\" >>\$sh_worker\n">>$mapScript

# if paired end reads
if [ "$isPaired" -eq "1" ]; then
    printf "    printf \' \'\$read1\' \'\$read2\' --readFilesCommand gunzip -c\\\\\\\'\"\\\n\" >>\$sh_worker\n">>$mapScript
# else single end reads
else
    printf "    printf \' \'\$read1\' --readFilesCommand gunzip -c\\\\\\\'\"\\\n\" >>\$sh_worker\n">>$mapScript
fi

printf "    printf \' --outSAMtype BAM SortedByCoordinate \\\\\\\'\"\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \' --outFileNamePrefix \'\$sampleshort\' \\\\\\\'\"\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \' --alignMatesGapMax 20000 \\\\\\\'\"\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \' --alignIntronMax 10000 \\\\\\\'\"\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \' --outFilterScoreMinOverLread 0.1 \\\\\\\'\"\\\n\" >>\$sh_worker\n">>$mapScript
printf "    printf \' --outFilterMatchNminOverLread 0.1 \'\"\\\n\" >>\$sh_worker\n">>$mapScript
printf "done\n">>$mapScript
printf "\n">>$mapScript
printf "## submit shell script\n">>$mapScript
printf "chmod 770 Shell_master_STAR.sh\n">>$mapScript
printf "bash Shell_master_STAR.sh\n">>$mapScript
printf "\n">>$mapScript
