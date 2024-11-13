#!/bin/bash
#SBATCH --array=1-12
#SBATCH --time=02:00:00
#SBATCH --mem=2g
#SBATCH --cpus-per-task=4
#SBATCH --job-name=slurm_array
#SBATCH --output=array_%J.out
#SBATCH --error=array_%J.err
#SBATCH --partition=pibu_el8

# Here I define important paths that I will be using and store them in variables.
WORKDIR="/data/users/asteiner/RNA-seq_paper/2_Quality_checks"
OUTDIR="$WORKDIR/Trimmed_QC_results"
SAMPLELIST="$WORKDIR/samplelist.txt"

# Then i also get the paths to the Reads i will use and to the samplenames and store them in variables.
SAMPLE=`awk -v line=$SLURM_ARRAY_TASK_ID 'NR==line{print $1; exit}' $SAMPLELIST`
READ1=`awk -v line=$SLURM_ARRAY_TASK_ID 'NR==line{print $2; exit}' $SAMPLELIST`
READ2=`awk -v line=$SLURM_ARRAY_TASK_ID 'NR==line{print $3; exit}' $SAMPLELIST`

# Here i specify where the quality control output should go.
OUTFILE="$OUTDIR/${SAMPLE}"

############################


# First i make sure the directories where i want to safe my results in exist. The -p command makes sure that all the
# needed parent directories will also be made in this step.
mkdir -p $OUTFILE

# Then it is important to load all the modules that will be used in the code later on.
module load Java/11.0.18
module load Trimmomatic/0.39-Java-11
module load FastQC/0.11.9-Java-11

# "java -jar $EBROOTTRIMMOMATIC/trimmomatic-0.39.jar": makes java run the trimmomatic command, which will trim my reads.
# "$EBROOTTRIMMOMATIC": is a variable that points to the directory where trimmomatic is installed.
# "PE": is used, because we are working with paired-end data (we have a read1 and read2 from the same sample).
# "-phred33": is used since we are using the phred33 quality scale (common in illumina reads).
# "-threats 4": means that the trimmomatic command will use 4 cpu threads and thus process things in parallel (-> faster).
# After that two input files are named (bc we are in the paired-end scenario there are 2 inputfiles), followed by the 4 output
# files that will be generated. A trimmed file and a file with the unpaired reads for read1 and read2.
# "LEADING:3", "TRAILING:3": will trim from the start and from the end all bases that have a phredscore quality lower than 3.
# "SLIDINGWINDOW:4:15": this will look at every window of 4 bases and if the average quality is lower than 15 it will trim from the 3' end.
# "MINLEN:50": This sets the minimal length to 50 bases, so all the reads that are shorter than this after trimming will be thrown out.
java -jar $EBROOTTRIMMOMATIC/trimmomatic-0.39.jar PE -phred33 -threads 4 $READ1 $READ2 ${SAMPLE}_1trim.fastq.gz ${SAMPLE}_1unpaired.fastq.gz ${SAMPLE}_2trim.fastq.gz ${SAMPLE}_2unpaired.fastq.gz LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:50

# The fastqc command does the Quality Control. The first two arguments are the inputfiles it will use (in this case the trimmed ones),
# the -o gives us the possibility to define the output file, and the argument after -o is the path and name to and of that outputfile.
fastqc ${SAMPLE}_1trim.fastq.gz ${SAMPLE}_2trim.fastq.gz -o $OUTFILE
