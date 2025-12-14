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
        concurrencyLimit: 1, // to introduce concurrent export limit reached
        timeoutMillis: 5000, // to introduce concurrent export limit reached
    });

    const metricReader = new PeriodicExportingMetricReader({
        exporter: metricExporter,
        // exportIntervalMillis: 5000,
        exportIntervalMillis: 100, // to introduce concurrent export limit reached
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