#!/bin/bash
set -e

PROJECT_NAME="sample-project"

# Check if directory exists
if [ -d "$PROJECT_NAME" ]; then
    echo "Error: Directory '$PROJECT_NAME' already exists in the current directory."
    echo "Please remove it or run this script in a different location."
    exit 1
fi

echo "Creating project structure for '$PROJECT_NAME'..."
mkdir -p "$PROJECT_NAME/src"

echo "Writing .dockerignore..."
cat << 'EOF' > "$PROJECT_NAME/.dockerignore"
node_modules
EOF

echo "Writing .env..."
cat << 'EOF' > "$PROJECT_NAME/.env"
HOST=0.0.0.0
PORT=8080
ENVIRONMENT=development
OTLP_ENDPOINT='http://localhost:4318/v1/metrics'
EOF

echo "Writing Dockerfile..."
cat << 'EOF' > "$PROJECT_NAME/Dockerfile"
FROM node:20-slim AS base

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

EXPOSE 8080

CMD ["node", "dist/index.js"]
EOF

echo "Writing nodejs-nodemon-debug.json..."
cat << 'EOF' > "$PROJECT_NAME/nodejs-nodemon-debug.json"
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Launch Program",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/src/index.ts",
      "runtimeExecutable": "${workspaceFolder}/node_modules/nodemon/bin/nodemon.js",
      "args": [">", "output.txt"]
    }
  ]
}
EOF

echo "Writing package.json..."
cat << 'EOF' > "$PROJECT_NAME/package.json"
{
  "name": "my-backend",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "dev": "nodemon --exec ts-node src/index.ts --inspect ",
    "build": "tsc -p tsconfig.json",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC",
  "description": "",
  "dependencies": {
    "@opentelemetry/api": "^1.9.0",
    "@opentelemetry/exporter-metrics-otlp-http": "^0.208.0",
    "@opentelemetry/sdk-metrics": "^2.2.0",
    "dotenv": "^16.4.7",
    "fastify": "^5.2.1"
  },
  "devDependencies": {
    "@types/node": "^22.10.5",
    "nodemon": "^3.1.9",
    "ts-node": "^10.9.2",
    "typescript": "^5.7.2"
  }
}
EOF

echo "Writing tsconfig.json..."
cat << 'EOF' > "$PROJECT_NAME/tsconfig.json"
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "moduleResolution": "node",
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
EOF

echo "Writing src/index.ts..."
cat << 'EOF' > "$PROJECT_NAME/src/index.ts"
import dotenv from 'dotenv';
import { createHistogram, initializeOtlp } from './metrics';

dotenv.config();

console.log("process.env::", process.env);

initializeOtlp();
const testHistogram = createHistogram('test-histogram');

function simulateCheckout() {

    testHistogram.record(4000, {
        'checkout.status': 'success',
        'user.tier': 'premium'
    });

}

setInterval(() => {
    const randomDuration = Math.floor(Math.random() * 3000);
    simulateCheckout(randomDuration);
}, 3000);

console.log('Node.js custom metrics application running...');
EOF

echo "Writing src/metrics.ts..."
cat << 'EOF' > "$PROJECT_NAME/src/metrics.ts"
import { metrics, ValueType } from '@opentelemetry/api';
import { MeterProvider, PeriodicExportingMetricReader, ConsoleMetricExporter } from '@opentelemetry/sdk-metrics';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
import { diag, DiagConsoleLogger, DiagLogLevel } from '@opentelemetry/api';

// Set the logger to print to the console
diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.DEBUG);

function initializeOtlp() {
    const priodicExporterMetricReader= getOtelPriodicExporterMetricReader();
    const consoleExporterMetricReader = getConsoleExporterMetricReader();

    const provider = new MeterProvider({
        readers: [priodicExporterMetricReader, consoleExporterMetricReader],
    });
    metrics.setGlobalMeterProvider(provider);
}

function getOtelPriodicExporterMetricReader(){
    const metricExporter = new OTLPMetricExporter({
        url: process.env.OTLP_ENDPOINT,
    });

    const metricReader = new PeriodicExportingMetricReader({
        exporter: metricExporter,
        exportIntervalMillis: 5000,
    });

    return metricReader;
}

function getConsoleExporterMetricReader(){
    const metricReader = new PeriodicExportingMetricReader({
        exporter: new ConsoleMetricExporter(),
        exportIntervalMillis: 5000,
    });

    return metricReader;
}

function createHistogram(name: string) {
    const meter = metrics.getMeter('custom-node-app-meter');
    return meter.createHistogram(name);
}

export { initializeOtlp, createHistogram }
EOF

echo "--------------------------------------------------------"
echo "Project '$PROJECT_NAME' has been successfully created."
echo "--------------------------------------------------------"
echo "Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. npm install"
echo "3. npm run dev"
