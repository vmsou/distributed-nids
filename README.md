# Distributed NIDS

## Quick Start

### Deploy
To deploy the NIDS cluster, run:
```bash
make compose-up workers=3 datanodes=3
```
or
```bash
docker network create nids_network --driver bridge
docker compose -f ./infra/hdfs/compose.yml up --scale datanode=3 -d &&
docker compose -f ./infra/spark/compose.yml up --scale worker=3 -d &&
docker compose -f ./infra/kafka/compose.yml up -d
```

### Interface URLs
- HDFS UI: http://localhost:9870
- Spark Master UI: http://localhost:8080
- Spark Jobs UI: http://localhost:4040

## Notebooks - Machine Learning
This project utilizes Spark MLlib. To prepare your own models, you can use the following links:
- [Setup Model](https://colab.research.google.com/drive/10v5uXBmioFk7bZeAtYbnHJ6-CS7OSq6U?usp=sharing)
- [Train Model](https://colab.research.google.com/drive/1V2kn61Jl1Hhnuv0KJpcvR3S6pqYt_2uE?usp=sharing)
- [Evaluate Model](https://colab.research.google.com/drive/1hrTI9o2uxjBrOD2hzKI_gn3sC5Rap-1Z?usp=sharing)

This "pipeline" enables to save each step of the model for reproducibility. You can also train and evaluate a model inside of the distributed
infrastructure with spark and hdfs with the apps `train-model.py` and `evaluate-model.py`, but setups files are necessary for these, which can be
made using the link above.


## Run on Docker
```bash
docker exec -it spark-master-1 bash
docker exec -it hdfs-namenode-1 bash
docker exec -it kafka-broker-1 bash
```

### Configuring HDFS - Setting environment up
```bash
docker exec -it hdfs-namenode-1 bash
hdfs dfs -mkdir -p /user/ /tmp/ /user/spark/ /user/spark/models /user/spark/datasets/ /user/spark/schemas /user/spark/setups

hdfs dfs -chmod 755 /user/
hdfs dfs -chmod -R 777 /tmp/

hdfs dfs -chown -R spark:spark /user/spark/
hdfs dfs -chmod -R 775 /user/spark/
```

### Configuring HDFS - Adding files (if needed)
- Schemas: JSON files of the DataFrame Schema
- Datasets: CSV or Parquet files
- Setups: Folders generated from saving a model before training (see setup model notebook)
- Models: Spark MLlib Models

You may need to use file:/// for local files
```bash
hdfs dfs -put <schema> /user/spark/schemas/
hdfs dfs -put <dataset> /user/spark/datasets/
hdfs dfs -put <setup> /user/spark/setups/
hdfs dfs -put <model> /user/spark/models/
```

### Configuring Kafka
```bash
docker exec -it kafka-broker-1 bash
kafka-topics.sh --create --topic NetV2 --bootstrap-server broker-1:9092
kafka-topics.sh --create --topic NetV2Alerts --bootstrap-server broker-1:9092
kafka-topics.sh --list --bootstrap-server broker-1:9092
kafka-console-producer.sh --broker-list broker-1:9092 broker-2:9092 broker-3:9092 --topic NetV2
>
```

### Submitting Application to Spark
```bash
make submit app="train-model.py cross-validator --folds 4 --parallelism 5 -s setups/<setup-name> --schema schemas/<schema-name>.json -d datasets/<dataset-name> -o models/<model-name>" cores=10 memory=1g
make submit app="evaluate-model.py -m models/<model-name> -d datasets/<dataset-name>" cores=7 memory=1g
make kafka-submit app="kafka-predictions.py --brokers broker-1:9092 --model models/<model-name> --schema schemas/<schema-name>.json --topic NetV2" cores=8
```
