
library(dplyr)
library(ggplot2)
library(ggpubr)
library(cowplot)
library(magick)
library(grid)
library(gridExtra)

root.dir = "./dab_score/data3/"
# Files with the DAB score data must have the label 'DAB'
# Files with the actual image of the ROI must have the label 'Area'
all_files = list.files(root.dir)

# Function that returns all the files within a label and a protein in a directory
filter_by_name <- function(files_list, protein, label){
  return(files_list[grepl(protein, files_list, fixed=T) & grepl(label, files_list, fixed=T)])
}


# Function that normalizes and standardizes the DAB values extracted from ImageJ
normalizeValues <- function(dab_scores){
  
  all_res <- c()
  for(i in 1:ncol(dab_scores)){
    all_res <- c(all_res, mean(dab_scores[,i], na.rm=T))
  }
  
  all_res <- 255-all_res
  all_res <- scale(all_res, center = F, scale = T)
  all_res = (all_res-min(all_res))/(max(all_res)-min(all_res))
  all_res <- all_res*1
  
}

all_polq_images.dir = filter_by_name(all_files, "POLQ", "Area")
all_glut_images.dir = filter_by_name(all_files, "GLUT", "Area")
all_polq_tables.dir = filter_by_name(all_files, "POLQ", "dab")
all_glut_tables.dir = filter_by_name(all_files, "GLUT", "dab")

# Initializing variables
m=1
type = "Human"
plot_list <- c()

# Start of the loop

for(z in 1:length(all_polq_images.dir)){

  z=1
  # Extracting the name of the sample
  sample_name <- gsub("_.*","",all_polq_tables.dir[z])
  
  # Loading the DAB score tables
  polq_table <- data.table::fread(paste0(root.dir, all_polq_tables.dir[z])) %>% as.data.frame()
  glut_table <- data.table::fread(paste0(root.dir, all_glut_tables.dir[z])) %>% as.data.frame()
  
  # Removing 0 values
  polq_table[polq_table == 0] <- NA
  glut_table[glut_table == 0] <- NA
  
  # Computing the normalized and standard DAB values
  all_res_polq <- normalizeValues(polq_table)
  all_res_glut <- normalizeValues(glut_table)
  
  # Unite the data in a data frame
  data <- data.frame(DAB_pct = c(all_res_polq, all_res_glut),
                     antibody = c(rep("POLQ", length(all_res_polq)),
                                  rep("GLUT1", length(all_res_glut))),
                     rectangle = c(1:length(all_res_polq), 1:length(all_res_glut)))
  
  # Generate a plot with the distributions of POLQ and GLUT1 with the image of the ROI
  single_plot <- ggplot(data, aes(rectangle, DAB_pct, colour = antibody)) + 
    geom_point() + 
    geom_smooth(se = FALSE) +
    ylab("Normalized DAB") +
    ggtitle(paste0("Comparison of GLUT1 and POLQ DAB - Sample: ", sample_name, " (",type," - Breast)")) +
    theme_half_open(12)  

  img1 <- image_read(paste0(root.dir, all_glut_images.dir[z]))
  img2 <- image_read(paste0(root.dir, all_polq_images.dir[z]))

  grob1 <- rasterGrob(img1, interpolate=TRUE, width=0.746, height = 1, x = 0.476)
  grob2 <- rasterGrob(img2, interpolate=TRUE, width=0.746, height = 1, x = 0.476)
  
  combined_plot <- arrangeGrob(grob1, grob2, single_plot, ncol=1, heights=c(1,1,10))
  plot_list[[z]] <- combined_plot
  dev.off()
  }

pdf("./Figures/POLQ-GLUT1_DAB.pdf", width=8, height=7)
for(grob in plot_list){
  grid.newpage()
  grid.draw(grob)
}
dev.off()

# Compute the correlation between POLQ and GLUT1 DAB values
# cor.test(all_res_polq, all_res_glut)


