workers ?= 1
datanodes ?= 1
localN ?= *
cores=1
memory=1g

# All
build-all: build-hdfs build-kafka build-spark

compose-up: create-network compose-up-hdfs compose-up-kafka compose-up-spark

compose-down: compose-down-spark compose-down-kafka compose-down-hdfs delete-network

compose-start: compose-start-hdfs compose-start-kafka compose-start-spark

compose-stop: compose-stop-spark compose-stop-kafka compose-stop-hdfs


# Network
create-network: 
	docker network create nids_network --driver bridge || true
delete-network: 
	docker network rm nids_network

# HDFS
build-hdfs:
	docker build -t vmsou/dnids-hdfs ./dockerfiles/hdfs
compose-up-hdfs: 
	docker compose -f ./infra/hdfs/compose.yml up --scale datanode=${datanodes} -d
compose-down-hdfs: 
	docker compose -f ./infra/hdfs/compose.yml down --volumes
compose-start-hdfs: 
	docker compose -f ./infra/hdfs/compose.yml start
compose-stop-hdfs: 
	docker compose -f ./infra/hdfs/compose.yml stop

# Spark
build-spark:
	docker build -t vmsou/dnids-spark ./dockerfiles/spark
compose-up-spark: 
	docker compose -f ./infra/spark/compose.yml up --scale worker=${workers} -d
compose-down-spark: 
	docker compose -f ./infra/spark/compose.yml down --volumes
compose-start-spark: 
	docker compose -f ./infra/spark/compose.yml start
compose-stop-spark: 
	docker compose -f ./infra/spark/compose.yml stop

# Kafka
build-kafka:
	docker build -t vmsou/dnids-kafka ./dockerfiles/kafka
compose-up-kafka: 
	docker compose -f ./infra/kafka/compose.yml up -d
compose-down-kafka: 
	docker compose -f ./infra/kafka/compose.yml down --volumes
compose-start-kafka: 
	docker compose -f ./infra/kafka/compose.yml start
compose-stop-kafka: 
	docker compose -f ./infra/kafka/compose.yml stop

# spark-submit
kafka-submit:
	docker exec spark-master-1 spark-submit --conf spark.executor.memory=${memory} --conf spark.cores.max=${cores} --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.1 ./apps/$(app)
scala-submit:
	docker exec spark-master-1 spark-submit --conf spark.executor.memory=${memory} --conf spark.cores.max=${cores} --class $(class) ./apps/$(app)
local-submit:
	docker exec spark-master-1 spark-submit --master local[${cores}] ./apps/$(app)
submit:
	docker exec spark-master-1 spark-submit --conf spark.executor.memory=${memory} --conf spark.cores.max=${cores} ./apps/$(app)
