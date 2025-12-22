const express = require('express');
const promClient = require('prom-client');
const logger = require('./utils/logger');
const helmet = require('helmet');
const cors = require('cors');

const app = express();

app.use(helmet());
app.use(cors());

const collectDefaultMetrics = promClient.collectDefaultMetrics;
collectDefaultMetrics();

// Custom Metric
const requestCounter = new promClient.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status'],
});

app.use((req, res, next) => {
    res.on('finish', () => {
        requestCounter.inc({
            method: req.method,
            route: req.path,
            status: res.statusCode,
        });
    });
    next();
});

app.get('/', (req, res) => {
    logger.info('Root endpoint called');
    res.json({ message: 'Hello from the Gold Standard Pipeline. Success simulation 4', version: '1.0.0' });
    //teste
    // logger.info('Root endpoint called - Simulating Failure');
    // res.status(500).json({ error: 'Critical Business Logic Failure' });
});

app.get('/health', (req, res) => {
    res.json({ status: 'UP', timestamp: new Date() });
});

app.get('/metrics', async (req, res) => {
    res.set('Content-Type', promClient.register.contentType);
    res.end(await promClient.register.metrics());
});

module.exports = app;
