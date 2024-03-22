

library(dplyr)
library(tidyverse)
library(rstatix)
library(boot)

CFA <- readRDS("./data/CFAs/CFA_data.rds")
CFA.metadata <- readRDS("./data/CFAs/CFA_metadata.rds")

CFA <- CFA %>% dplyr::select(Score = Saturation, everything())

term <- mean(CFA$Score[CFA$Condition == CFA.metadata$ctrl])
CFA$Score <- CFA$Score/term*100

compute_bliss_synergy <- function(data, indices) {

  # Selected Bootstrap samples
  sampled_data <- data[indices, ] 
  
  # Ensuring all conditions are present
  if (!all(c(CFA.metadata$ctrl, CFA.metadata$drug1, 
             CFA.metadata$drug2, CFA.metadata$combo) %in% 
           unique(sampled_data$Condition))) {
    return(NA_real_) # Numeric NA to conserve a numerical structure
  }
  
  # Scale the values
  mean_scores <- aggregate(Score ~ Condition, data = sampled_data, FUN = mean)
  
  # Check if all required conditions have been sampled
  if(nrow(mean_scores) < 4) {
    return(NA_real_) # Not all conditions are represented
  }
  
  drug1_eff <- 100-mean_scores$Score[mean_scores==CFA.metadata$drug1]
  drug2_eff <- 100-mean_scores$Score[mean_scores==CFA.metadata$drug2]
  combo_eff <- 100-mean_scores$Score[mean_scores==CFA.metadata$combo]
  
  bliss_score <- combo_eff-(100*(1-((1-(drug1_eff/100))*(1-(drug2_eff/100)))))
  
  return(bliss_score)
}

bliss_score <- compute_bliss_synergy(CFA, 1:nrow(CFA))

set.seed(123)

bootstrap_results <- boot(data = CFA, statistic = compute_bliss_synergy, R = 1000)
# Remove results that didn't meet the conditions
valid_results <- na.omit(bootstrap_results$t)

# Regenerate the boot object with only valid results, error if there isn't any.
if(length(valid_results) > 0) {

  filtered_boot <- bootstrap_results
  filtered_boot$t <- valid_results
  filtered_boot$R <- length(valid_results)
  # Compute the Confidence Intervals 
  ci <- boot.ci(boot.out = filtered_boot, type = "perc")
} else {
  print("No valid bootstrap results were obtained.")
}

sub_results <- data.frame(cell_line = CFA.metadata$cell_line,
                          drugs = CFA.metadata$drugs, 
                          DMSO_effect = mean(CFA$Score[CFA$Condition==CFA.metadata$ctrl]), 
                          drug1_effect = mean(CFA$Score[CFA$Condition==CFA.metadata$drug1]), 
                          drug2_effect = mean(CFA$Score[CFA$Condition==CFA.metadata$drug2]), 
                          combo_effect = mean(CFA$Score[CFA$Condition==CFA.metadata$combo]), 
                          bliss_synergy = bliss_score, 
                          ci_low = ci$percent[[4]],
                          ci_high = ci$percent[[5]],
                          synergy = "")

results <- sub_results %>%
  mutate(synergy = case_when(
    ci_high < -10 ~ "Antagonist",
    ci_low > 10 ~ "Synergistic",
    TRUE ~ "Additive"
  ))

colnames(results) <- c("Cell line", "Drugs", "DMSO effect", 
                       "Drug1 effect", "Drug2 effect", "Combo effect", 
                       "Bliss synergy", "CI low", "CI high", "Synergy")

write.table(results, "./results/CFAs/CFAdata.txt",
            row.names = F, sep="\t", quote = F)




