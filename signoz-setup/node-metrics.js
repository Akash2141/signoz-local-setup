// metrics.js

const { metrics, ValueType } = require('@opentelemetry/api');
const { MeterProvider, PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');

// Define the endpoint of your SigNoz OTel Collector (default port 4318 for HTTP metrics)
// Replace 'localhost' with your VM's IP if the app is on a different machine
const OTLP_ENDPOINT = 'http://localhost:4318/v1/metrics'; 

// 1. Configure the Exporter
const metricExporter = new OTLPMetricExporter({
    url: OTLP_ENDPOINT,
});

// 2. Configure the Metric Reader
const metricReader = new PeriodicExportingMetricReader({
    exporter: metricExporter,
    // Collect and export metrics every 5 seconds
    exportIntervalMillis: 5000, 
});

// 3. Configure the Meter Provider
const provider = new MeterProvider({
    // Pass the metricReader directly into the constructor's 'readers' array
    readers: [metricReader], 
});

// 4. Set the Meter Provider globally
metrics.setGlobalMeterProvider(provider);

// 5. Get a Meter (used to create instruments)
const meter = metrics.getMeter('custom-node-app-meter');

// --- Custom Metrics Instruments ---

// A Counter: To count the total number of checkouts
const checkoutCounter = meter.createCounter('checkout_events_total', {
    description: 'Counts the number of completed user checkouts',
    valueType: ValueType.INT,
});

// A Histogram: To measure the duration of a checkout process
const checkoutDurationHistogram = meter.createHistogram('checkout_duration_seconds', {
    description: 'Measures the duration of the checkout process',
    unit: 's',
});


// --- Logic to record metrics ---

function simulateCheckout(durationMs) {
    console.log(`Simulating checkout with duration ${durationMs}ms...`);
    
    // 1. Increment the counter (for total checkouts)
    checkoutCounter.add(1, { 
        'checkout.status': 'success', 
        'user.tier': 'premium' 
    });

    // 2. Record the duration in the histogram (convert ms to seconds)
    checkoutDurationHistogram.record(durationMs / 1000, {
        'checkout.step': 'payment'
    });
}

// Simulate checkouts every 3 seconds
setInterval(() => {
    // Random duration between 500ms and 3500ms
    const randomDuration = Math.floor(Math.random() * 3000) + 500;
    simulateCheckout(randomDuration);
}, 3000);

console.log('Node.js custom metrics application running...');