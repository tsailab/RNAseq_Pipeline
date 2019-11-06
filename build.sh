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
countDir=${rootDir}/count
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
mkdir $countDir
mkdir $resultsDir
mkdir $scriptsDir


###
### Clone NGS clean dir
###
git clone https://github.com/tsailab/NGSclean.git $NGScleanDir


###
### Copy genome and annotation
###
cp -r ${genomeOriDir} ${genomeDir}
gtfFile=${genomeAnnoDir}/$(ls $genomeAnnoDir | grep 'gtf$' | head -1)
cp ${gtfFile} ${genomeDir}/gene.gtf


### 2 - Run NGS Clean
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
printf "cd ${cleanDir}\n" >> "${trimCleanFile}"
printf "ml Python/3.6.6-foss-2018b\n" >> "${trimCleanFile}"
printf "${NGScleanDir}/trim_and_clean.py -d RNAseq_design.txt" \
    >> "${trimCleanFile}"
printf " -t 8 -s merge --run_trimmomatic ${trimmoFull}" \
    >> "${trimCleanFile}"
printf " --load_trimmo_module ${trimmo_module}" \
    >> "${trimCleanFile}"
printf " --adaptor ${adaptor}" \
    >> "${trimCleanFile}"
printf " --run_star ${starFull} --load_star_module ${star_module}\n" \
    >> "${trimCleanFile}"

# Submit the jobs
printf "\n" >> "${trimCleanFile}"
printf "chmod 750 Run_RNAseq_design.sh\n" >> "${trimCleanFile}"
printf "./Run_RNAseq_design.sh\n" >> "${trimCleanFile}"

# Summarize the files when job is done
summaryFile="${scriptsDir}/03-get-summary.sh"
printf "cd ${cleanDir}\n" > "${summaryFile}"
printf "python ${NGScleanDir}/get_trim_sum.py\n" >> "${summaryFile}"




###
### Mapping
###
mapScript=${scriptsDir}/04map.sh
workingDir=${mapDir}
dataDir=${cleanDir}
genome=${genomeDir}

printf "cd $workingDir\n">$mapScript
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


###
### Read Counting
###
countScript=${scriptsDir}/05count.sh
workingDir=${countDir}
bamDir=${mapDir}

printf "cd $workingDir\n">$countScript
printf "\n">>$countScript
printf "master=\"Shell_master_FeatureC.sh\"\n">>$countScript
printf "printf \"#\"\'!\'/bin/bash\"\\\n\" >\$master\n">>$countScript
printf "index=0\n">>$countScript
printf "for bam in \$bamDir/*.bam\n">>$countScript
printf "do\n">>$countScript
printf "    sample1=\${bam%%%%Aligned.sortedByCoord.out.bam}\n">>$countScript
printf "    sample=\${sample1##*/}\n">>$countScript
printf "    out=\$sample\"_counts.txt\"\n">>$countScript
printf "    index=\$((\$index+1))\n">>$countScript
printf "    sh_worker=\"run\"\$index\"_\"\$sample\".sh\"\n">>$countScript
printf "    printf \"qsub \"\$sh_worker\"\\\n\">>\$master\n">>$countScript
printf "    printf \"#\"\'!\'/bin/bash\"\\\n\">\$sh_worker\n">>$countScript
printf "    printf \"#PBS -N FeatureC_\"\$sample\"\\\n\">>\$sh_worker\n">>$countScript
printf "    printf \"#PBS -q batch\\\n\">>\$sh_worker\n">>$countScript
printf "    printf \"#PBS -l nodes=1:ppn=12:Intel\\\n\">>\$sh_worker\n">>$countScript
printf "    printf \"#PBS -l walltime=12:00:00\\\n\">>\$sh_worker\n">>$countScript
printf "    printf \"#PBS -l mem=30gb\\\n\">>\$sh_worker\n">>$countScript
printf "    printf \"cd $workingDir\\\n\">>\$sh_worker\n">>$countScript
printf "    printf \"ml Subread/1.6.2 \\\n\">>\$sh_worker\n">>$countScript
printf "    printf \'featureCounts -Q 2 -M --fraction -s 0 -T 12 -p -C \\\\\\\'\"\\\n\">>\$sh_worker\n">>$countScript
printf "    printf \' -a $genomeDir/gene.gtf \\\\\\\'\"\\\n\">>\$sh_worker\n">>$countScript
printf "    printf \' -o \'\$out\' \'\$bam\' \'>>\$sh_worker\n">>$countScript
printf "done\n">>$countScript
printf "\n">>$countScript
printf "## submit jobs\n">>$countScript
printf "chmod 770 \$master\n">>$countScript
printf "bash \$master\n">>$countScript


###
### Count merge
###
mergeScript=${scriptsDir}/06merge.sh
printf "cd $countDir\n">$mergeScript
printf "ml Python/3.6.6-foss-2018b\n">>$mergeScript
printf "python $NGScleanDir/Merge_featureCounts_Folder.py $countDir all_counts.tsv\n">>$mergeScript


###
### Put results for step 2 in $resultsDir
###
resultsScript=${scriptsDir}/07get-results.sh
printf "grep \"\" $mapDir/*Log.final.out > $resultsDir/all_mapping_logs.txt\n">$resultsScript
printf "cp $countDir/all_counts.tsv $resultsDir/counts.txt\n">>$resultsScript
