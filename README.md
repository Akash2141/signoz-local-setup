Note: Due to networking issue on podman 3.4.4 replace the podman with docker for this implementation

# Git Clone Signoz Repo
```sh
$ git clone https://github.com/SigNoz/signoz.git
$ cd signoz/deploy/docker/
$ docker compose up -d
```

# Complete flow of signoz
1. Data Source (Your Local Machine)
**Component:** Your local host file system.

**Action:** You have a log file, project.log, residing on your local machine.

2. Ingestion - The OpenTelemetry Collector Receiver
**Component:** The otel-collector-filelog Docker container running the OpenTelemetry Collector Contrib image.

**Mechanism:** Docker Volume Mount

The docker-compose.yaml file creates a Volume Mount that links your local file's path (e.g., /path/to/project.log) to a path inside the collector container (e.g., /var/log/project.log). This makes the file accessible to the container.

**Mechanism:** Filelog Receiver

The filelog/project_log receiver (defined in otel-collector-config.yaml) actively monitors (or "tails") the file at the mounted path (/var/log/project.log).

When a new line is written to project.log, the filelog receiver reads it and converts it into a standardized OpenTelemetry Log Record object.

3. Processing - The Pipeline
**Component:** The processors section (e.g., batch) in the otel-collector-config.yaml.

**Action:** The raw log record enters the logs pipeline.

**Parsing:** If you add log parsing operators (like regex_parser), the processor extracts fields (e.g., timestamp, log level) from the raw text body and promotes them to structured attributes.

**Batching:** The batch processor buffers multiple log records together. This is essential for efficiency, as it minimizes network connections and improves throughput when exporting data.

4. Storage - The Exporter and Backend
**Component:** The otlp exporter and the SigNoz ClickHouse Database.

**Mechanism:** OTLP Export

The otlp exporter takes the batch of standardized OpenTelemetry Log Records and sends them using the OpenTelemetry Protocol (OTLP) over gRPC to the main SigNoz endpoint (typically the otel-collector service or a direct ClickHouse endpoint).

The SigNoz application receives the OTLP data.

**Mechanism:** Data Storage

SigNoz's backend service ingests the data and writes it into the dedicated ClickHouse database tables, where it is stored in a highly compressed and query-optimized format.

5. Visualization - SigNoz UI
Component: SigNoz Query Service and ReactJS Frontend.

Action: Data is displayed to the user.

When you open the Logs Explorer tab in the SigNoz UI (http://localhost:3301), the frontend sends a request to the Query Service.

The Query Service translates your search queries (e.g., filters, time ranges) into optimized SQL queries against the ClickHouse database.

ClickHouse executes the query quickly and returns the matching log records.

The SigNoz UI renders the log records in a table format, allowing you to see the original message, timestamp, and any structured attributes (like service name or log level).

# Relationship between three key components in the OpenTelemetry ecosystem: the **Filelog Receiver**, the **OTLP Exporter**, and the **OTLP Collector**.

This relationship defines how log data moves from a source file into a structured monitoring system like SigNoz.

### 1. **OpenTelemetry Collector** (OTLP Collector)
The term **OpenTelemetry Collector (OTLP Collector)** is a bit redundant but refers to the central application itself. It's a stand-alone service that acts as a vendor-neutral data processing pipeline.

* **Role:** The **host** and **engine** for all data processing.
* **Function:** It receives, processes, and exports all telemetry data (logs, metrics, and traces). It is typically configured using a YAML file that defines its different pipelines.

---

### 2. **Filelog Receiver**
The Filelog Receiver is a **plugin** that works *inside* the OpenTelemetry Collector.

* **Role:** The **input mechanism** for log files.
* **Function:** It is configured in the Collector's YAML under the `receivers` section. Its job is to ingest data from an external source—specifically, by tailing and parsing local log files. Once it reads a log line, it converts that raw text into a standardized **OpenTelemetry Log Record** object and injects it into the Collector's processing pipeline.

$$\text{Filelog Receiver} \xrightarrow{\text{reads, tails, converts}} \text{OpenTelemetry Log Record}$$

---

### 3. **OTLP Exporter**
The OTLP Exporter is another **plugin** that works *inside* the OpenTelemetry Collector.

* **Role:** The **output mechanism** for structured data.
* **Function:** It is configured in the Collector's YAML under the `exporters` section. Its job is to take the processed telemetry data (logs in this case) and package them using the **OpenTelemetry Protocol (OTLP)**. It then sends this structured, compressed data over the network to the final backend system (like SigNoz).

$$\text{OpenTelemetry Log Record} \xrightarrow{\text{packages, sends via OTLP}} \text{SigNoz Backend}$$

---

## 🔗 The Complete Relationship Flow

All three components are chained together within the Collector's **Log Pipeline** to move your `project.log` data to SigNoz:

1.  **Filelog Receiver (Input):** Reads the raw text from `project.log`.
2.  **OTLP Collector (Engine):** Hosts the receiver, manages the pipeline (which can include processors for filtering or enrichment), and then passes the data to the exporter.
3.  **OTLP Exporter (Output):** Takes the processed data and sends it using the OTLP network protocol to the ingestion endpoint of your SigNoz instance.

In summary, the **OTLP Collector** is the container that runs the **Filelog Receiver** to bring data *in* and the **OTLP Exporter** to send data *out*. 


# Run Multi file command 
```sh
$ docker compose -f signoz/deploy/docker/docker-compose.yaml -f docker-compose.yaml up -d
```

# Docker down using multi line
```sh
$ docker compose -f signoz/deploy/docker/docker-compose.yaml -f docker-compose.yaml down -v
```

# Add Manual Logs
```sh
$ echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Manual test log line added." >> project.log
```

# Recrete after changes
```sh
$ docker compose -f signoz/deploy/docker/docker-compose.yaml -f docker-compose.yaml up -d --force-recreate
```

# Logs to verify in signoz log collector
```sh
$ docker logs signoz-file-log-collector
```
```sh
$ docker logs signoz-otel-collector
```

# When signoz otel collector shows the error try restarting it
```sh
$ docker restart signoz-otel-collector
```

# Fake Credentials
Email: test@test.com
Password: TestSignoz@1234