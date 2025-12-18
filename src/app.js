const express = require('express');
const promClient = require('prom-client');
const logger = require('./utils/logger');
const helmet = require('helmet');
const cors = require('cors');

const app = express();

// Security Middleware
app.use(helmet());
app.use(cors());

// Prometheus Metrics Setup
const collectDefaultMetrics = promClient.collectDefaultMetrics;
collectDefaultMetrics();

// Custom Metric
const requestCounter = new promClient.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status'],
});

// Middleware to count requests
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
    res.json({ message: 'Hello from the Gold Standard Pipeline!', version: '1.0.0' });
});

app.get('/health', (req, res) => {
    res.json({ status: 'UP', timestamp: new Date() });
});

// Metrics Endpoint for Prometheus to scrape
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', promClient.register.contentType);
    res.end(await promClient.register.metrics());
});

module.exports = app;
