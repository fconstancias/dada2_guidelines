## ------------------------------------------------------------------------
#This script merges together all tables generated in the runs and assigns taxonomy to 
#each ASV from the whole table 

library(dada2); packageVersion("dada2")
library(tidyverse)

args <- commandArgs(trailingOnly = TRUE)

seqtables <- strsplit(args[1], ",")[[1]]
output <- args[2]
name <- args[3]
tax_db <- args[4]
tax_db_sp <- args[5]
trim_length <- as.integer(strsplit(args[6], ",")[[1]]) 

dir.create(file.path(output, "02_mergeruns-taxonomy"), showWarnings = FALSE)
dir.create(file.path(output, "02_mergeruns-taxonomy", name), showWarnings = FALSE)

output <- paste0(output,"/02_mergeruns-taxonomy/",name,"/")

# Get all the rds files
list.df <- map(seqtables, readRDS)

st.all <- mergeSequenceTables(tables = list.df)

track.final <- data.frame(sample = rownames(st.all),
                          chimera.removed = rowSums(st.all))

seqtab.raw <- removeBimeraDenovo(st.all, method="consensus",
                                     multithread=TRUE)

print("Chimera removed!\n") 


total <- sum(colSums(seqtab.raw))

track.final$chimera.removed  <- rowSums(seqtab.raw)

# Trim the unespecific amplifications from our dataset
seqtab <- seqtab.raw[,nchar(colnames(seqtab.raw)) %in% seq(trim_length[1],
                                                           trim_length[2])]

track.final <- track.final %>% 
                    mutate( too_long_variants = rowSums(seqtab))

final <- sum(colSums(seqtab))

print(" Trimmed by length (cutting the band):\n")
print(paste0("A total of: ", round((final * 100) / total, digits =2), " reads are kept!"))

print(" Collapsing at 100% id")

seqtab <- collapseNoMismatch(seqtab,  minOverlap = 50)

track.final <- track.final %>% 
                    mutate( collapsed_100 = rowSums(seqtab))


saveRDS(seqtab, paste0(output, name, "_seqtab_final.rds"))

# Extract the FASTA from the dataset
uniquesToFasta(seqtab,
               paste0(output, name, "_seqtab_final.fasta"),
               ids= paste0("asv",c(1:ncol(seqtab)), ";size=", colSums(seqtab)))

# Assign taxonomy (general)
set.seed(42) #random  generator necessary for reproductibility

tax <- assignTaxonomy(seqtab,
                    tax_db, 
                    multithread=TRUE,minBoot=80)
# minboot: N of idntical bootstraps to gen. identification

print("Taxonomy assigned, to Genus level")

head(unname(tax))

# Assign species
tax.sp <- addSpecies(tax, tax_db_sp, verbose=TRUE, allowMultiple=3)


print("Taxonomy assigned, to Species level!")

# Write to disk
saveRDS(tax.sp, paste0(output, name, "_tax_assignation.rds")) 


track.final <- track.final %>% 
               mutate( diff.total = collapsed_100 / raw  %>% round(digits =2))

write_tsv(track.final, paste0(output, name, "_track_analysis_final.tsv"))

