wd = "E:/Work/Know-Center/NASA_ADS/output_clustering/clustering_output/bollenstyle"

wd = "E:/Work/Know-Center/test_parsing/ipython_notebooks"

placement_mode = "tsne"
diag_mode = "max"

#######################
init(wd)
preprocessing(diag_mode, sim_mode)

#######################
run_main(wd, placement_mode, diag_mode, sim_mode)

#######################
clustering()
run_nmds()

#######################
run_tsne(1000, 50)
plot(tsne_pos, pch=areas)

#######################
final_output()

#######################
wds = c("astro-ph.GA_top_100", "astro-ph.CO_top_100", "astro-ph.EP_top_100",
        "astro-ph.HE_top_100", "astro-ph.IM_top_100", "astro-ph.SR_top_100")
placements = c("tsne", "nmds", "man")
man_clusters = c(3,3,3,3,3,2)

i = 1
for (folder in wds) {
  for (placement_mode in placements) {
    num_clusters = man_clusters[i]
    wd = paste("E:/Work/Know-Center/NASA_ADS/output/clustering_output", folder, sep="")
    cat(paste(wd, num_clusters, placement_mode, "/n"))
    run_main(wd, placement_mode, diag_mode, sim_mode)
  }
  i = i+1
}

########################
pvclust::pvclust(cooc_matrix_sym, method.hclust="ward.D", method.distance="cosine", nboot=100)
