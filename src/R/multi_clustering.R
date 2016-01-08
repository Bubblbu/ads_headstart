wd = "E:/Work/Know-Center/NASA_ADS/output/clustering_output"
wd_ext = c("100","200","300")

placement_mode = "tsne"
diag_mode <<- "max"
dist_mode <<- "euclidean"

num_clusters = c(5,6,7,8)
clust_methods = c("ward.D","ward.D2")

for (ext in wd_ext) {
  wd = paste(wd_base, ext, sep="")
  
  init(wd)
  preprocessing(diag_mode, sim_mode, dist_mode)
  
  cat("\nK-Means clustering\n")
  for (n_clust in num_clusters) {
    kc = kmeans(cooc_matrix_sym, n_clust)
    purity = ClusterPurity(kc$cluster, metadata$prim_cat)
    
    cat(paste("n_clust", n_clust, "- purity:", purity, "- n_clusters:", n_clust, "\n"))
  }
  
  cat("\nHclust + elbow\n")
  for (clust_method in clust_methods) {
    css_cluster <<- css.hclust(distance_matrix, hclust.FUN.MoreArgs=list(method=clust_method))
    cut_off <<- elbow.batch(css_cluster,inc.thres=c(0.01,0.05,0.1),
                            ev.thres=c(0.95,0.9,0.8,0.75,0.67,0.5,0.33,0.2,0.1),precision=3)
    
    elbow_num_clusters <<- cut_off$k
    meta_cluster <<- attr(css_cluster,"meta")
    cluster <<- meta_cluster$hclust.obj
    clust_labels <<- labels(distance_matrix)
    areas <<- cutree(cluster, k=elbow_num_clusters)
    
    purity = ClusterPurity(areas, metadata$prim_cat)
    cat(paste("meth", clust_method, "- purity:", purity, "- n_clusters:", elbow_num_clusters, "\n"))
    
    for (n_clust in num_clusters) {
      purity = ClusterPurity(cutree(cluster, k=n_clust), metadata$prim_cat)
      cat(paste("meth", clust_method, "- purity:", purity, "- n_clusters:", n_clust, "\n"))
    }
  }
}
