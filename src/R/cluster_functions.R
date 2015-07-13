library(GMD)
library(MASS)
library(ecodist)
library(tm)
library(proxy)
library(SnowballC)
library(lsa)
library(tsne)

init <- function(wd){
  setwd(wd)
  metadata <<- read.csv("metadata.csv")
  cooc <<- read.csv("cooc.csv", header=FALSE)
  
  output_dir = paste(wd,paste("/",placement_mode,"_diag_",diag_mode,sep=""),sep="")
  cat(output_dir, "\n")
  dir.create(output_dir, showWarnings = F)
  setwd(output_dir)
  
  cooc_matrix_sym <<- tapply(as.numeric(cooc$V3), list(cooc$V1, cooc$V2), max)
}

preprocessing <- function(diag, sim){
  cooc_matrix_sym[is.na(cooc_matrix_sym)] <<- 0
  if(diag == "max"){
    for (row in 1:nrow(cooc_matrix_sym)) {
      cooc_matrix_sym[row, row] <<- max(cooc_matrix_sym[,row])
    }
  } else if(diag == "zero") {
    diag(cooc_matrix_sym) <<- 0
  } else if(diag == "NA") {
    diag(cooc_matrix_sym) <<- NA
  }
  
  a <- table(cooc_matrix_sym)
  sparsity <<- a[names(a)==0]/sum(a)
  cat(paste("Sparsity:", sparsity, "\n"))
  
  if(isSymmetric(cooc_matrix_sym) == FALSE)  {
    stop("Input matrix not symmetric")
  }
  
  cooc_matrix_cor <<- cosine(cooc_matrix_sym)
  distance_matrix <<- as.dist(1-cooc_matrix_cor)
}


clustering <- function() {
  # Perform clustering, use elbow to determine a good number of clusters
  css_cluster <<- css.hclust(distance_matrix, hclust.FUN.MoreArgs=list(method="ward.D"))
  cut_off <<- elbow.batch(css_cluster,inc.thres=c(0.01,0.05,0.1),
                        ev.thres=c(0.95,0.9,0.8,0.75,0.67,0.5,0.33,0.2,0.1),precision=3)
  num_clusters <<- cut_off$k
  meta_cluster <<- attr(css_cluster,"meta")
  cluster <<- meta_cluster$hclust.obj
  clust_labels <<- metadata$id
  areas <<- cutree(cluster, k=num_clusters)
  
  cat(num_clusters)
  
  # Plot result of clustering to PDF file
  pdf("clustering.pdf", width=19, height=12)
  plot(cluster, labels=metadata$prim_cat, cex=0.6)
  rect.hclust(cluster, k=num_clusters, border="red")
  dev.off()
}

run_nmds <- function(){
  # Perform non-metric multidimensional scaling
  nm <<- nmds(distance_matrix, mindim=2, maxdim=2)
  nm.nmin <<- nmds.min(nm)
  x <<- nm.nmin$X1
  y <<- nm.nmin$X2
  
  # Plot results from multidimensional scaling, highlight clusters with symbols
  pdf("placement.pdf")
  plot(nm.nmin, pch=areas)
  dev.off()
  
  # Write some stats to a file
  file_handle <- file("stats.txt", open="w")
  writeLines(c(paste("Number of Clusters:", num_clusters, sep=" ")
               , paste("Description:", attributes(cut_off)$description)
               , paste("Stress:", min(nm$stress), sep=" ")
               , paste("R2:", max(nm$r2), sep=" ")
               , paste("\nSparsity:", sparsity)), file_handle)
  close(file_handle)
}

run_tsne <- function(max_iter, perp){
  tsne_pos <<- tsne(distance_matrix, max_iter = max_iter, perplexity = perp)
  x <<- tsne_pos[,1]
  y <<- tsne_pos[,2]
  
  clust_labels <<- metadata$id
  
  tsne_dist = distance(data.matrix(tsne_pos))
  
  css_cluster <<- css.hclust(tsne_dist, hclust.FUN.MoreArgs=list(method="average"))
  cut_off <<- elbow.batch(css_cluster,inc.thres=c(0.01,0.05,0.1),
                          ev.thres=c(0.95,0.9,0.8,0.75,0.67,0.5,0.33,0.2,0.1),precision=3)
  num_clusters <<- cut_off$k
  meta_cluster <<- attr(css_cluster,"meta")
  cluster <<- meta_cluster$hclust.obj
  
  areas <<- cutree(cluster, k=num_clusters)
  
  pdf("clustering.pdf", width=19, height=12)
  plot(cluster, labels=metadata$prim_cat, cex=0.6)
  rect.hclust(cluster, k=num_clusters, border="red")
  dev.off()
  
  pdf("placement.pdf")
  plot(tsne_pos, pch=areas)
  dev.off()
  
  file_handle <- file("stats.txt", open="w")
  writeLines(c(paste("Number of Clusters:", num_clusters),
               paste("\nSparsity:", sparsity)), file_handle)
  close(file_handle)
}


final_output <- function() {
  # Prepare the output
  result <<- cbind(x,y,areas,clust_labels)
  output <<- merge(metadata, result, by.x="id", by.y="clust_labels", all=TRUE)
  
  col_pos = seq(1:length(colnames(output)))
  switch_index = which(colnames(output) %in% c("areas","title","paper_abstract"))
  rest_index = col_pos[! col_pos %in% switch_index]
  column_order = c(switch_index, rest_index)
  
  # Write output to file
  file_handle <<- file("output_scaling_clustering.csv", open="w")
  write.csv(output[column_order], file=file_handle, row.names=FALSE)
  close(file_handle)
}

run_main <- function(wd, placement_mode, diag_mode, sim_mode, dist_mode) {
  init(wd)
  preprocessing(diag_mode, sim_mode, dist_mode)
  
  if (placement_mode == "tsne") {
    run_tsne(1000, 50)
    final_output()
  } else if (placement_mode =="nmds") {
    clustering()
    run_nmds()
    final_output()
  } else {
    tsne_pos <<- tsne(distance_matrix, max_iter = 1000, perplexity = 50)
    x <<- tsne_pos[,1]
    y <<- tsne_pos[,2]
    
    clust_labels <<- 1:length(tsne_pos[,1])
    
    tsne_dist = distance(data.matrix(tsne_pos))
    
    css_cluster <<- css.hclust(tsne_dist, hclust.FUN.MoreArgs=list(method="average"))
    cut_off <<- elbow.batch(css_cluster,inc.thres=c(0.01,0.05,0.1),
                            ev.thres=c(0.95,0.9,0.8,0.75,0.67,0.5,0.33,0.2,0.1),precision=3)
    meta_cluster <<- attr(css_cluster,"meta")
    cluster <<- meta_cluster$hclust.obj
    
    areas <<- cutree(cluster, k=num_clusters)
    
    pdf("clustering.pdf", width=19, height=12)
    plot(cluster, labels=metadata$title, cex=0.6)
    rect.hclust(cluster, k=num_clusters, border="red")
    dev.off()
    
    pdf("placement.pdf")
    plot(tsne_pos, pch=areas)
    dev.off()
    
    file_handle <- file("stats.txt", open="w")
    writeLines(c(paste("Number of Clusters:", num_clusters),
                 paste("\nSparsity:", sparsity)), file_handle)
    close(file_handle)
    
    final_output()
  }
}

ClusterPurity <- function(clusters, classes) {
  sum(apply(table(classes, clusters), 2, max)) / length(clusters)
}