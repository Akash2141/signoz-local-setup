#!/bin/bash
set -e

PROJECT_NAME="sample-project-python"

# Check if directory exists
if [ -d "$PROJECT_NAME" ]; then
    echo "Error: Directory '$PROJECT_NAME' already exists in the current directory."
    echo "Please remove it or run this script in a different location."
    exit 1
fi

echo "Creating project structure for '$PROJECT_NAME'..."
mkdir -p "$PROJECT_NAME"

echo "Writing .dockerignore..."
cat << 'EOF' > "$PROJECT_NAME/.dockerignore"
__pycache__
virtualenv
.env
EOF

echo "Writing .env..."
cat << 'EOF' > "$PROJECT_NAME/.env"
HOST=0.0.0.0
PORT=8080
ENVIRONMENT=development
# Note: Python OTLP HTTP exporter typically expects the full path
OTLP_ENDPOINT='http://localhost:4318/v1/metrics'
EOF

echo "Writing Dockerfile..."
cat << 'EOF' > "$PROJECT_NAME/Dockerfile"
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "app.py"]
EOF

echo "Writing requirements.txt..."
cat << 'EOF' > "$PROJECT_NAME/requirements.txt"
opentelemetry-api
opentelemetry-sdk
opentelemetry-exporter-otlp-proto-http
python-dotenv
EOF

echo "Writing app.py (equivalent to index.ts)..."
cat << 'EOF' > "$PROJECT_NAME/app.py"
import os
import time
import random
from dotenv import load_dotenv
from metrics import initialize_otlp, create_histogram

# Load environment variables
load_dotenv()

print(f"Environment Variables Loaded. OTLP_ENDPOINT: {os.getenv('OTLP_ENDPOINT')}")

# Initialize OpenTelemetry
initialize_otlp()
test_histogram = create_histogram('test-histogram')

def simulate_checkout():

    # Record the value. 
    # Note: Python OTel attributes are a dictionary.
    test_histogram.record(4000, {
        'checkout.status': 'success',
        'user.tier': 'freemium'
    })

print('Python custom metrics application running...')

if __name__ == "__main__":
    try:
        while True:
            simulate_checkout()

    except KeyboardInterrupt:
        print("\nExiting...")
EOF

echo "Writing metrics.py (equivalent to metrics.ts)..."
cat << 'EOF' > "$PROJECT_NAME/metrics.py"
import os
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
import logging
logging.basicConfig(level=logging.DEBUG)
# logging.getLogger('opentelemetry').setLevel(logging.DEBUG)

# 2. ADD THIS: Silence the noisy HTTP connection logs
# This tells urllib3: "Only bother me if there is a Warning or Error"
# logging.getLogger('urllib3').setLevel(logging.WARNING)

def initialize_otlp():
    endpoint = os.getenv('OTLP_ENDPOINT', 'http://localhost:4318/v1/metrics')
    
    # Initialize the OTLP HTTP Metric Exporter
    metric_exporter = OTLPMetricExporter(endpoint=endpoint)

    # Create a MetricReader that exports metrics periodically (every 5 seconds)
    metric_reader = PeriodicExportingMetricReader(
        exporter=metric_exporter,
        export_interval_millis=5000,
    )

    # Create a MeterProvider with the reader
    provider = MeterProvider(metric_readers=[metric_reader])
    
    # Set the global MeterProvider
    metrics.set_meter_provider(provider)

def create_histogram(name: str):
    meter = metrics.get_meter('custom-python-app-meter')
    return meter.create_histogram(name)
EOF

echo "--------------------------------------------------------"
echo "Project '$PROJECT_NAME' has been successfully created."
echo "--------------------------------------------------------"
echo "Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. python3 -m venv venv"
echo "3. source venv/bin/activate"
echo "4. pip install -r requirements.txt"
echo "5. python app.py"
