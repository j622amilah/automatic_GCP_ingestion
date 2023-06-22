#!/bin/bash

# ./step1_open_files.sh


clear




# ---------------------------------------------
# Data Ingestion
# ---------------------------------------------
# 0. GCP : 
#     - 0: download zip data from AWS bucket to PC - get desired csv files - load csv to cloud to many temporary tables - Append all the temporary tables into one Table on a certain column (UNION ALL ) - delete the temporary tables - save the unioned table  
    
#     - 1: download zip data from AWS bucket to PC - upload csv to GCP bucket - use cloud dataprep 


# AWS :
#     - 0: download zip data from AWS bucket to PC - upload csv to AWS bucket -
    
    
    


# ---------------------------------------------
# Setup google cloud sdk path settings
# ---------------------------------------------
export val=$(echo "X1")

if [[ $val == "X0" ]]
then 
    # Google is SDK is not setup correctly - one needs to relink to the gcloud CLI everytime you restart the PC
    source '/usr/lib/google-cloud-sdk/path.bash.inc'
    source '/usr/lib/google-cloud-sdk/completion.bash.inc'
    export PATH="/usr/lib/google-cloud-sdk/bin:$PATH"
    
    # Get latest version of the Google Cloud CLI
    gcloud components update
else
    echo "Do not setup google cloud sdk PATH"
fi



# ---------------------------------------------
# Obtenir des informations Authorization
# ---------------------------------------------
export val=$(echo "X1")

if [[ $val == "X0" ]]
then 
    # Way 0 : gcloud init


    # Way 1 : gcloud auth login

    # A browser pop-up allows you to authorize with your Google account
    gcloud auth login

    # ******* need to set up this
    # gcloud auth login --no-launch-browser
    # gcloud auth login --cred-file=CONFIGURATION_OR_KEY_FILE
    
    # Allow for google drive access, moving files to/from GCP and google drive
    # gcloud auth login --enable-gdrive-access
    
else
    echo ""
    # echo "List active account name"
    # gcloud auth list
fi




# ---------------------------------------------
# Make random number for creating variable or names
# ---------------------------------------------
if [[ $val == "X1" ]]
then 
    let "randomIdentifier=$RANDOM*$RANDOM"
else
    let "randomIdentifier=202868496"
fi

# ---------------------------------------------



# ---------------------------------------------
# Set Desired location
# https://cloud.google.com/bigquery/docs/locations
# ---------------------------------------------
# Set the project region/location
# export location=$(echo "europe-west9-b")  # Paris
export location=$(echo "europe-west9")  # Paris
# export location=$(echo "EU")
# export location=$(echo "US")   # says US is the global option

# ---------------------------------------------





# ---------------------------------------------
# SELECT PROJECT_ID
# ---------------------------------------------
export val=$(echo "X1")

if [[ $val == "X0" ]]
then

    gcloud services enable iam.googleapis.com \
        bigquery.googleapis.com \
        logging.googleapis.com
  
fi

# ---------------------------------------------



# I0621 21:44:04.235584 139898542389056 bigquery_client.py:730] There is no apilog flag so non-critical logging is disabled.
# sudo chmod 777 /usr/lib/google-cloud-sdk/platform/bq/bigquery_client.py
# gedit /usr/lib/google-cloud-sdk/platform/bq/bigquery_client.py



# ---------------------------------------------
# SELECT PROJECT_ID
# ---------------------------------------------
export val=$(echo "X0")

if [[ $val == "X0" ]]
then 
    # List projects
    gcloud config list project
    
    # Set project
    export PROJECT_ID=$(echo "northern-eon-377721")
    gcloud config set project $PROJECT_ID

    # List DATASETS in the current project
    # bq ls $PROJECT_ID:
    # OR
    bq ls

    #  datasetId         
    #  ------------------------ 
    #   babynames               
    #   city_data               
    #   google_analytics_cours  
    #   test       

    # ------------------------

fi

# ---------------------------------------------







# ---------------------------------------------
# SELECT dataset_name
# ---------------------------------------------
export val=$(echo "X0")

if [[ $val == "X0" ]]
then 

    # Create a new DATASET named PROJECT_ID
    # export dataset_name=$(echo "google_analytics")
    # bq --location=$location mk $PROJECT_ID:$dataset_name

    # OR 

    # Use existing dataset
    export dataset_name=$(echo "google_analytics")

    # ------------------------

    # List TABLES in the dataset
    echo "bq ls $PROJECT_ID:$dataset_name"
    bq --location=$location ls $PROJECT_ID:$dataset_name

    #           tableId            Type    Labels   Time Partitioning   Clustered Fields  
    #  -------------------------- ------- -------- ------------------- ------------------ 
    #   avocado_data               TABLE                                                  
    #   departments                TABLE                                                  
    #   employees                  TABLE                                                  
    #   orders                     TABLE                                                  
    #   student-performance-data   TABLE                                                  
    #   warehouse                  TABLE

    # ------------------------

    echo "bq show $PROJECT_ID:$dataset_name"
    bq --location=$location show $PROJECT_ID:$dataset_name

    #    Last modified             ACLs             Labels    Type     Max time travel (Hours)  
    #  ----------------- ------------------------- -------- --------- ------------------------- 
    #   08 Mar 11:40:52   Owners:                            DEFAULT   168                      
    #                       j622amilah@gmail.com,                                               
    #                       projectOwners                                                       
    #                     Writers:                                                              
    #                       projectWriters                                                      
    #                     Readers:                                                              
    #                       projectReaders  

    # ------------------------

fi


# ---------------------------------------------


export val=$(echo "X1")

if [[ $val == "X0" ]]
then 
    echo "---------------- Query upload csv files to tables ----------------"
    
    cd /home/oem2/Documents/ONLINE_CLASSES/Spécialisation_Google_Data_Analytics/3_Google_Data_Analytics_Capstone_Complete_a_Case_Study/ingestion_folder/csvdata/exact_match_header
    
    if [ -f file_list_names ]; then
       rm file_list_names
    fi
  
    if [ -f table_list_names ]; then
       rm table_list_names
    fi
    
    # Get list of csv files
    ls  | sed 's/file_list_names//g' | sed '/^$/d' >> file_list_names
    
    
    # Generic name of tables
    export Generic_CSV_FILENAME=$(cat file_list_names | head -n 1 | sed 's/.csv//g' | tr -d [0-9] | sed 's/-//g' | sed 's/  */ /g' | sed 's/^ *//g' | tr '[:upper:]' '[:lower:]' | sed -e '/[[:space:]]\+$/s///' | sed 's/[[:space:]]/_/g')
    
    # Load CSV file into a BigQuery table FROM PC
    cnt=0
    for CSV_NAME in $(cat file_list_names)
    do
       # cut off .csv from the filename
       #export CSV_FILENAME=${CSV_NAME/.csv/}
       # export TABLE_name=$(echo "${CSV_FILENAME}${cnt}")
       
       export TABLE_name=$(echo "${Generic_CSV_FILENAME}${cnt}")
       
       # Need to save a list of TABLE_name, to do the UNION query next
        echo $TABLE_name >> table_list_names
       # OR
       # Save tables to a dataset folder dedicated to one thing, and use bq ls to get table names in next query
       
        bq load \
            --location=$location \
            --source_format=CSV \
            --skip_leading_rows=1 \
            #--autodetect \
            $dataset_name.$TABLE_name \
            ./$CSV_NAME \
                        #ride_id:string,rideable_type:string,started_at:timestamp,ended_at:timestamp,start_station_name:string,start_station_id:string,end_station_name:string,end_station_id:string,start_lat:float,start_lng:float,end_lat:float,end_lng:float,member_casual:string
       cnt=$((cnt + 1))
       
    done
    
fi


# ---------------------------------------------


export val=$(echo "X1")

if [[ $val == "X0" ]]
then 
    echo "---------------- update the table schema ----------------"
    
    # Step 1: Get main path
    export cur_path=$(echo "/home/oem2/Documents/ONLINE_CLASSES/Spécialisation_Google_Data_Analytics/3_Google_Data_Analytics_Capstone_Complete_a_Case_Study/ingestion_folder/csvdata/exact_match_header")
    echo "cur_path"
    echo $cur_path
    
    cd $cur_path
    
    cnt=0
    for TABLE_name in $(cat table_list_names)
    do  
        echo "TABLE_name:"
        echo $TABLE_name
    
	bq --location=$location update $PROJECT_ID:$dataset_name.$TABLE_name ${cur_path}/myschema.json
    
        cnt=$((cnt + 1))
        
    done
    
fi


# ---------------------------------------------


export val=$(echo "X1")

if [[ $val == "X0" ]]
then 
    
    
    echo "---------------- Query UNION the Tables ----------------"
    # Key : All the headers for the files need to be the same
    
    export cur_path=$(echo "/home/oem2/Documents/ONLINE_CLASSES/Spécialisation_Google_Data_Analytics/3_Google_Data_Analytics_Capstone_Complete_a_Case_Study/ingestion_folder/csvdata/exact_match_header")
    echo "cur_path"
    echo $cur_path
    
    cd $cur_path
    
    export output_TABLE_name_prev=$(echo "output_TABLE_name_prev")
    export output_TABLE_name_cur=$(echo "output_TABLE_name_cur")
    
    # bq ls $PROJECT_ID:$dataset_name
    cnt=1
    for TABLE_name in $(cat table_list_names)
    do  
        echo "TABLE_name:"
        echo $TABLE_name
        
        
        # The output_TABLE_name can not be the same as an existing table, so it is necessary to change the table name after a UNION 
        if [[ $cnt == 0 ]]; then
            # Just save this table to have and output name
            
            # Create output_TABLE_name_prev
            echo "-----------------------------------"
            bq query \
            --location=$location \
            --destination_table $PROJECT_ID:$dataset_name.$output_TABLE_name_prev \
            --allow_large_results \
            --use_legacy_sql=false \
            'SELECT CAST(ride_id AS STRING) AS ride_id,
            CAST(rideable_type AS STRING) AS rideable_type,
            CAST(started_at AS STRING) AS started_at,
            CAST(ended_at AS STRING) AS ended_at,
             CAST(start_station_name AS STRING) AS start_station_name,
             CAST(start_station_id AS STRING) AS start_station_id,
             CAST(end_station_name AS STRING) AS end_station_name,
             CAST(end_station_id AS STRING) AS end_station_id,
             CAST(start_lat AS STRING) AS start_lat,
             CAST(start_lng AS STRING) AS start_lng,
             CAST(end_lat AS STRING) AS end_lat,
             CAST(end_lng AS STRING) AS end_lng,
             CAST(member_casual AS STRING) AS member_casual
             FROM `northern-eon-377721.google_analytics.'$TABLE_name'`;'
            echo "-----------------------------------"
            
            # It fails: says table is not found ... does it take time to make the table??
            # echo "-----------------------------------"
            # echo "Print length of Unioned table"
            # Print length of Unioned table
            # bq query \
            # --location=$location \
            # --allow_large_results \
            # --use_legacy_sql=false \
            # 'SELECT COUNT(*) FROM `northern-eon-377721.google_analytics.'$output_TABLE_name_cur'`;'
            echo "-----------------------------------"
            
        else
            
            # Here the table exists and it puts start_station_id and end_station_id as INTEGER
            echo "-----------------------------------"
            echo "Confirm matching table schema of both tables:"
            echo "-----------------------------------"
            echo "Show schema of output_TABLE_name_prev"
            bq --location=$location show \
		--schema \
		--format=prettyjson \
		$PROJECT_ID:$dataset_name.$output_TABLE_name_prev
            
            echo "Show schema of TABLE_name"
            bq --location=$location show \
		--schema \
		--format=prettyjson \
		$PROJECT_ID:$dataset_name.$TABLE_name
            echo "-----------------------------------"
            
            
            echo "-----------------------------------"
            echo "Union tables"
            # Union tables : UNION only takes distinct values, but UNION ALL keeps all of the values selected
            bq query \
            --location=$location \
            --destination_table $PROJECT_ID:$dataset_name.$output_TABLE_name_cur \
            --allow_large_results \
            --use_legacy_sql=false \
            'SELECT CAST(ride_id AS STRING) AS ride_id,
            CAST(rideable_type AS STRING) AS rideable_type,
            CAST(started_at AS STRING) AS started_at,
            CAST(ended_at AS STRING) AS ended_at,
            CAST(start_station_name AS STRING) AS start_station_name,
            CAST(start_station_id AS STRING) AS start_station_id,
            CAST(end_station_name AS STRING) AS end_station_name,
            CAST(end_station_id AS STRING) AS end_station_id,
            CAST(start_lat AS STRING) AS start_lat,
            CAST(start_lng AS STRING) AS start_lng,
            CAST(end_lat AS STRING) AS end_lat,
            CAST(end_lng AS STRING) AS end_lng,
            CAST(member_casual AS STRING) AS member_casual
            FROM `northern-eon-377721.google_analytics.'$output_TABLE_name_prev'`
            UNION ALL 
            SELECT CAST(ride_id AS STRING) AS ride_id,
            CAST(rideable_type AS STRING) AS rideable_type,
            CAST(started_at AS STRING) AS started_at,
            CAST(ended_at AS STRING) AS ended_at,
            CAST(start_station_name AS STRING) AS start_station_name,
            CAST(start_station_id AS STRING) AS start_station_id,
            CAST(end_station_name AS STRING) AS end_station_name,
            CAST(end_station_id AS STRING) AS end_station_id,
            CAST(start_lat AS STRING) AS start_lat,
            CAST(start_lng AS STRING) AS start_lng,
            CAST(end_lat AS STRING) AS end_lat,
            CAST(end_lng AS STRING) AS end_lng,
            CAST(member_casual AS STRING) AS member_casual
            FROM `northern-eon-377721.google_analytics.'$TABLE_name'`;'
            echo "-----------------------------------"
            
            echo "-----------------------------------"
            echo "Print length of Unioned table"
            # Print length of Unioned table
            bq query \
            --location=$location \
            --allow_large_results \
            --use_legacy_sql=false \
            'SELECT COUNT(*) FROM `northern-eon-377721.google_analytics.'$output_TABLE_name_cur'`;'
            echo "-----------------------------------"
            
            echo "-----------------------------------"
            #echo "Delete output_TABLE_name_prev"
            # Delete output_TABLE_name_prev because it is now in output_TABLE_name_cur
            bq --location=$location rm -f -t $PROJECT_ID:$dataset_name.$output_TABLE_name_prev
            echo "-----------------------------------"
            
            echo "-----------------------------------"
            # https://cloud.google.com/bigquery/docs/managing-tables#renaming-table
            echo "copy table output_TABLE_name_cur to output_TABLE_name_prev"
            bq --location=$location cp \
            -a -f -n \
            $PROJECT_ID:$dataset_name.$output_TABLE_name_cur \
            $PROJECT_ID:$dataset_name.$output_TABLE_name_prev
            echo "-----------------------------------"
            
            echo "-----------------------------------"
            # Delete output_TABLE_name_cur because it is now in output_TABLE_name_prev
            bq --location=$location rm -f -t $PROJECT_ID:$dataset_name.$output_TABLE_name_cur
            echo "-----------------------------------"
            
        fi
        
        cnt=$((cnt + 1))
        
    done
    
fi


# ---------------------------------------------


# -----------------
# Backup/Copy table
# -----------------
export val=$(echo "X1")

if [[ $val == "X0" ]]
then 
    
    echo "Backup/Copy table:"
    export output_TABLE_name=$(echo "output_TABLE_name_prev")
    export output_TABLE_name_backup=$(echo "bikeshare_table0")
    
    bq --location=$location cp \
            -a -f -n \
            $PROJECT_ID:$dataset_name.$output_TABLE_name \
            $PROJECT_ID:$dataset_name.$output_TABLE_name_backup

fi


# ---------------------------------------------

# -----------------
# Random additonal 
# -----------------
export val=$(echo "X0")

if [[ $val == "X0" ]]
then 
    
    # bq rm -t $PROJECT_ID:$dataset_name.output_TABLE_name_prev_backup
    bq rm -t $PROJECT_ID:$dataset_name.output_TABLE_name_prev
fi


# ---------------------------------------------


# -----------------
# List buckets
# -----------------
export val=$(echo "X1")

if [[ $val == "X0" ]]
then 
    
    echo "list buckets"
    gcloud storage ls

fi


# ---------------------------------------------


export val=$(echo "X1")

if [[ $val == "X0" ]]
then 
    
    export output_TABLE_name_prev=$(echo "output_TABLE_name_prev")
    
    # Save final_table in bucket
    bq extract --location=$location \
               --destination_format=CSV \
               --field_delimiter=',' \
               --print_header=boolean \
               $PROJECT_ID:$dataset_name.$output_TABLE_name_prev \
               gs://the_bucket4/myFile.csv
    
fi


# ---------------------------------------------


export val=$(echo "X1")

if [[ $val == "X0" ]]
then 
    
    echo "---------------- Query Delete Tables ----------------"
    
    cd /home/oem2/Documents/ONLINE_CLASSES/Spécialisation_Google_Data_Analytics/3_Google_Data_Analytics_Capstone_Complete_a_Case_Study/ingestion_folder/csvdata/exact_match_header
    
    # put table names to be deleted in a file list
    # bq ls --format=json $PROJECT_ID:$dataset_name | jq -r .[].tableReference.tableId >> table_list_names
    
    for TABLE_name in $(cat table_list_names)
    do
       # -t signifies table
       bq rm -t $PROJECT_ID:$dataset_name.$TABLE_name
    done
    
    
fi


# ---------------------------------------------




