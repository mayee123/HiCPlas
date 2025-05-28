import csv
import subprocess
import sys
import re

csv.field_size_limit(sys.maxsize)

def run1(file, tax):
    with open(file) as file:
       
        tsv_file = csv.reader(file, delimiter="\t")
        
        count=0
        dict={}
        for line in tsv_file:
            size=int(line[3])
            count+=size
            if line[0]=="C":
                if tax=="S":
                    taxonomy=line[2].split(" (")[0]
                elif tax=="G":
                    taxonomy=line[2].split(" (")[0].split(" ")[0]
                if taxonomy in dict:
                    dict[taxonomy][0]+=1
                    dict[taxonomy][1]+=size
                else:
                    dict[taxonomy]=[1,size]
            

        max_key = max(dict, key=dict.get)
        perc=dict[max_key][1]/count
        if perc >= 0.1:

        
            perc=str(round(perc*100,2))+"%"
            contig=dict[max_key][0]
            output=(f"{perc}\t{contig}\t{max_key}")
            subprocess.run(["echo", "-e", output])


            
        print(dict)



def run(file_path, tax_level):
    count = 0
    taxonomy_stats = {}

    with open(file_path, newline='') as file:
        tsv_reader = csv.reader(file, delimiter="\t")

        for line in tsv_reader:
            try:
                size = int(line[3])
            except ValueError:
                continue  # skip header or non-numeric lines

            count += size

            if line[0] == "C":
                if tax_level == "S":
                    taxonomy = " ".join(re.sub(r"\s*\(.*?\)", "", line[2]).split()[:2])
                elif tax_level == "G":
                    taxonomy = " ".join(re.sub(r"\s*\(.*?\)", "", line[2]).split()[:1])
                else:
                    continue  # skip if tax_level is invalid

                if taxonomy in taxonomy_stats:
                    taxonomy_stats[taxonomy][0] += 1
                    taxonomy_stats[taxonomy][1] += size
                else:
                    taxonomy_stats[taxonomy] = [1, size]

    # Get key with highest total size
    max_key = max(taxonomy_stats, key=lambda k: taxonomy_stats[k][1])
    total_size = taxonomy_stats[max_key][1]
    percentage = total_size / count

    if percentage >= 0.5:
        formatted_percentage = f"{round(percentage * 100, 2)}%"
        contig_count = taxonomy_stats[max_key][0]
        output = f"{formatted_percentage}\t{contig_count}\t{max_key}"
        subprocess.run(["echo", "-e", output])


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python filter_kraken.py <input_file> <tax_level (S or G)>")
        sys.exit(1)

    input_file = sys.argv[1]
    tax_level = sys.argv[2]

    run(input_file, tax_level)