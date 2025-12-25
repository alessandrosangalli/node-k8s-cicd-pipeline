const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

// The SDK will look for the following environment variables:
// OTEL_EXPORTER_OTLP_ENDPOINT: The URL of the OTel Collector (e.g. http://otel-collector:4318)
// OTEL_SERVICE_NAME: The name of the service

const sdk = new NodeSDK({
    resource: new Resource({
        [SemanticResourceAttributes.SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || 'node-k8s-app',
        [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'development',
    }),
    traceExporter: new OTLPTraceExporter(),
    metricExporter: new OTLPMetricExporter(),
    instrumentations: [getNodeAutoInstrumentations()],
});

// Initialize the SDK and register with the OpenTelemetry API
console.log('OpenTelemetry: Initializing SDK...');
try {
    sdk.start();
    console.log('OpenTelemetry: SDK started successfully (Service: %s, Endpoint: %s)',
        process.env.OTEL_SERVICE_NAME || 'node-k8s-app',
        process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318');
} catch (error) {
    console.error('OpenTelemetry: Failed to start SDK', error);
}

// Gracefully shut down the SDK on process exit
process.on('SIGTERM', () => {
    sdk.shutdown()
        .then(() => console.log('Tracing terminated'))
        .catch((error) => console.log('Error terminating tracing', error))
        .finally(() => process.exit(0));
});

module.exports = sdk;
