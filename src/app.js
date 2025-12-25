const express = require('express');
const promClient = require('prom-client');
const logger = require('./utils/logger');
const helmet = require('helmet');
const cors = require('cors');
const packageJson = require('../package.json');

const app = express();

app.use(helmet());
app.use(cors());

const collectDefaultMetrics = promClient.collectDefaultMetrics;
collectDefaultMetrics();

const requestCounter = new promClient.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status'],
});

const httpRequestDurationMicroseconds = new promClient.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status'],
    buckets: [0.1, 0.5, 1, 1.5, 2, 5],
});

app.use((req, res, next) => {
    const end = httpRequestDurationMicroseconds.startTimer();
    res.on('finish', () => {
        requestCounter.inc({
            method: req.method,
            route: req.path,
            status: res.statusCode,
        });
        end({
            method: req.method,
            route: req.path,
            status: res.statusCode,
        });
    });
    next();
});

app.get('/', (req, res) => {
    logger.info('Root endpoint called');
    res.json({ message: 'Hello from the Gold Standard Pipeline. Success simulation 8' });
    //
    // logger.info('Root endpoint called - Simulating Failure');
    // res.status(500).json({ error: 'Critical Business Logic Failure' });
});

app.get('/health', (req, res) => {
    res.json({ status: 'UP', timestamp: new Date() });
    //res.status(500).json({ error: 'Critical Business Logic Failure' });
});

app.get('/metrics', async (req, res) => {
    res.set('Content-Type', promClient.register.contentType);
    res.end(await promClient.register.metrics());
});

app.get('/version', (req, res) => {
    res.json({
        version: packageJson.version,
        name: packageJson.name,
        description: packageJson.description
    });
});


// Global Error Handler
app.use((err, req, res, next) => {
    logger.error(`${err.status || 500} - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
    res.status(err.status || 500).json({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'production' ? 'An unexpected error occurred' : err.message
    });
});

module.exports = app;
