library(jsonlite)
library(aRxiv)

input_dir = "E:/Work/Know-Center/NASA_ADS/files/ads_data/ads_arxiv_id/"
output_dir = "E:/Work/Know-Center/NASA_ADS/files/ads_data/ads_prim_cat/"

cats = list.files(input_dir)

for (category in cats) {
  if (category == "Astrophysics.json" || category == "Quantitative Finance.json" ||
      category == "Statistics.json" || category == "Computer Science.json") {
    next
  }
  cat(category)
  json_file <- paste(input_dir, category, sep = "")
  
  json_data = fromJSON(json_file)
  json_data_omit = na.omit(json_data)
  
  prim_cats = arxiv_search(id_list = json_data_omit$arxiv_id, batchsize=200,
                           limit=nrow(json_data_omit),force=TRUE)$primary_category
  
  json_data_omit$prim_cat = prim_cats
  write(toJSON(json_data_omit, dataframe = "columns"), paste(output_dir,  category, sep=""))
}