from __future__ import division, print_function
import numpy as np
import pandas as pd
import math

# Read in ADS data and sort by reader_count
df = pd.read_csv("../files/ads_harvard_data.csv")
df.reader_ids = df.reader_ids.astype(str)
df.sort("readers", ascending=False, inplace=True)

# Settings
number_of_papers = 100

# List of reader id's
readers = []
count = 0
for idx, row in df.iterrows():
    if count == number_of_papers:
        break
    readers.append(row['reader_ids'][1:-1].split(";"))
    count += 1

# Create metadata.csv
print("*** Writing metadata.csv")
metadata = df[0:number_of_papers]
metadata['id'] = range(1, number_of_papers + 1)
metadata.to_csv("../files/metadata.csv", index=False)

# Co-occurence matrix
# cooc = np.zeros((len(readers)+1, len(readers)+1), dtype=int)

# Adjacency list of co-reads
output = []

print("*** Creating adjacency list of co-reads")
max_iter = sum(range(1, len(readers)))
count = 1
for idx1, list1 in enumerate(readers, start=1):
    for idx2, list2 in enumerate(readers, start=1):
        if idx2 > idx1:
            print("{} out of {}".format(count, max_iter))
            count += 1
            co_read = len(set(list1) & set(list2))
            if co_read != 0:
                output.append([idx1, idx2, co_read])
                output.append([idx2, idx1, co_read])

                # cooc[idx2, idx1] = co_read
                #     cooc[idx1, idx2] = co_read
                # elif idx1 == idx2:
                #     cooc[idx1, idx1] = 0

# for i in range(1,len(readers)+1):
# cooc[0, i] = i
#     cooc[i, 0] = i

output = np.array(output)
np.savetxt("../files/cooc.csv", output, delimiter=",")

print("Sparsity: {}".format(len(output)/2/len(readers)**2))