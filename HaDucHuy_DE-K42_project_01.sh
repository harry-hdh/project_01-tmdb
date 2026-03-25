#!/bin/bash

# Download file

wget -O tmdb-movies-raw.csv  https://raw.githubusercontent.com/yinghaoz1/tmdb-movie-dataset-analysis/master/tmdb-movies.csv


#cut -d, -f1-11,13- tmdb-movies-raw.csv > tmdb-movies-clean1.csv

# Clean commas & newline within text 
awk -v RS='"' '
NR % 2 == 0 { 
    gsub(/\n/, " ", $0); 
    gsub(/,/, ";", $0) 
} 
{ printf "%s%s", $0, RT }' tmdb-movies-raw.csv > tmdb-movies-clean1.csv

# Remove corupted text
tr -cd '\11\12\15\40-\176' < tmdb-movies-clean1.csv  > tmdb-movies-clean2.csv
#iconv -c -f cp1255 -t utf8 tmdb-movies-clean1.csv 

#Remove unused columns
#cut -d, -f1-7,9,11,13- tmdb-movies-clean2.csv > tmdb-movies-clean3.csv
awk -F',' 'BEGIN{OFS=","} {print $1,$3,$4,$5,$6,$7,$9,$11,$13,$14,$15,$16,$17,$18,$19,$20,$21}' tmdb-movies-clean2.csv > tmdb-movies-clean3.csv

#Format date from combine year to release_date yyyy-mm-dd
head -n 1 tmdb-movies-clean3.csv > tmdb-movies-clean-final.csv;
awk -F',' 'BEGIN{OFS=","} FNR > 1 {
    split($12, d, "/");
    if (length(d[1]) == 1) d[1] = "0" d[1];
    if (length(d[2]) == 1) d[2] = "0" d[2];
    $12 = $15 "-" d[1] "-" d[2];
    print
}' tmdb-movies-clean3.csv >> tmdb-movies-clean-final.csv

#Clean up
rm tmdb-movies-clean1.csv tmdb-movies-clean3.csv tmdb-movies-clean2.csv;

# 1. Sort by release date
{ head -n 1 tmdb-movies-clean-final.csv ; tail -n +2 tmdb-movies-clean-final.csv | sort -t "," -k12,12r; } > tmdb-movies-sorted-by-release_date.csv ;

# 2. Movie with 7.5 average rating or more 
awk -F','  'BEGIN {OFS=","} { if ($14 >= 7.5)  print }' tmdb-movies-clean-final.csv > tmdb-movies-filter-by-vote_avg.csv;

# 3.Highest and lowest revenue movies
{ tail -n +2 tmdb-movies-clean-final.csv | sort -t "," -k4,4r | awk -F',' 'NR==1 {print "Movie has highest revenue: ", $5," - ",$4} END{print "Movie has lowest revenue: ", $5," - ",$4}'; printf '%.s─' $(seq 1 $(tput cols)); } > cau_3.txt

# 4. Total revenue
{ awk -F',' '{sum+=$4} END {print "Total revenue: ", sprintf("%.0f",sum)}' tmdb-movies-clean-final.csv; printf '%.s─' $(seq 1 $(tput cols)); } > cau_4.txt

# 5. Top 10 movies with highest revenue
{ 
echo "Top 10 movies with highest revenue:"; 
tail -n +2 tmdb-movies-clean-final.csv | sort -t "," -k4,4r | awk -F',' '{print $5," - ",$4} NR==10{exit}'; 
printf '%.s─' $(seq 1 $(tput cols));
} > cau_5.txt

# 6.
{ 
echo "Director with most movies:"; tail -n +2 tmdb-movies-clean-final.csv | awk -F',' 'BEGIN{OFS=","}{ n = split($7, arr, "|");
        for (i = 1; i<=n; i++) count[arr[i]]++ } 
        END{for (val in count) print val " | " count[val]}' | sort -t"|" -k2,2rn | head -n 1;  printf '\n'; 

echo "Actor/ess with most movies:"; tail -n +2 tmdb-movies-clean-final.csv | awk -F',' 'BEGIN{OFS=","}{ n = split($6, arr, "|");
        for (i = 1; i<=n; i++) count[arr[i]]++ } 
        END{for (val in count) print val " | " count[val]}' | sort -t"|" -k2,2rn | head -n 1;  printf '%.s─' $(seq 1 $(tput cols));         
} > cau_6.txt

# 7. Categories
{
echo "Film categories:";
tail -n +2 tmdb-movies-clean-final.csv | awk -F',' 'BEGIN{OFS=","}{ n = split($10, arr, "|");
	for (i = 1; i<=n; i++) count[arr[i]]++ } 
	END{for (val in count) print val "-" count[val]}' | sort -t"-" -k1,1; 
printf '%.s─' $(seq 1 $(tput cols));
} > cau_7.txt	

#8. Top 5 popular films & average movie lengh
{ echo "Top 5 Most Popular Films By Vote Count:"; tail -n +2 tmdb-movies-clean-final.csv | sort -t "," -k13,13rn | awk -F',' 'NR==6{exit}{print $5," - ",$13}'; printf '%.s─' $(seq 1 $(tput cols)); } > cau_8.txt

{ awk -F',' '{sum+=$9} END { if ( NR > 0 ) print "Average movies length: " sum / NR " mins"}' tmdb-movies-clean-final.csv; printf '%.s─' $(seq 1 $(tput cols)); } >> cau_8.txt

# Clean up dir move output files to dir
DIRECTORY="files"
rm -rf "$DIRECTORY"
mkdir "$DIRECTORY"
mv *.txt "$DIRECTORY"
mv *.csv "$DIRECTORY"

