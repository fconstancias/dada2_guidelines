#!/bin/sh

#SBATCH --account=<your-account>
#SBATCH --job-name=merge
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=<num-threads>
#SBATCH --output=analysis/logs/merge_%J.out
#SBATCH --error=analysis/logs/merge_%J.err

clear

date

### DADA2 pipeline ######
## ~~ Trimming, error generation and DADA2 run ~~ ##

#Trimming of the reads (and filtering with maxEE), 
#generation of an error model whit the probabilities 
#transitions between bases (A -> T) and dada2 algorithm. 
#BEFORE continue the pipeline, PLEASE, check the error plot
#(a .pdf generated in the output dir). 

## ARGS ##

#[1] /seqtables/ each of them separated by a comma.  
#                The path should be the complete one. With many seqtables, 
#                first they are merged and then bimeras are tested. 

#[2] /output dir/ Directory output, usually analysis (a subdirectory will be created).

#[3] /name/ A common identifier to be sure that the output is the 
#            correct one. You will thank us that :^)

#[4] /Taxonomy db (general)/ The db has to be downloaded from https://benjjneb.github.io/dada2/training.html
#                             and saved in the biocluster. It can be in .gz, no problem! 

#[5] /Taxonomy db (species)/ The db has to be downloaded from https://benjjneb.github.io/dada2/training.html
#                             and saved in the biocluster. It can be in .gz, no problem!

#[6] /trim length/ After all the processing, some unespecific amplified reads still are present in the samples. 
#                   Time to cut them down. Specify with a range which read you want to keep (Example: 400,450)

module load gcc/4.9.0
module load Rstats/R-3.4.1

Rscript scripts/2_mergeruns-taxonomy.R  \
                    analysis/1_errors-output/blanes_project/blanes_projectseqtab.rds \
                    analysis/ \
                    blanes_project \
                    data/assign_tax/rdp_train_set_16.fa.gz \
                    data/assign_tax/rdp_species_assignment_16.fa.gz \
                    400,450 

# If you have multple seqtabs, it should be written like this:

#analysis/1_errors-output/blanes_project/blanes4020,analysis/1_errors-output/blanes_project/blanes4300 ...

# a Pain in the ass, we know. Sorry for that! 
