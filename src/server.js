require('./tracing');
const app = require('./app');
const logger = require('./utils/logger');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
    logger.info(`Server running on port ${PORT}`);
});

// Graceful Shutdown
const shutdown = (signal) => {
    logger.info(`${signal} signal received: closing HTTP server`);

    // Safety timeout: force close after 10 seconds if connections don't drain
    const forceClose = setTimeout(() => {
        logger.error('Could not close connections in time, forceful shutdown');
        process.exit(1);
    }, 10000);

    server.close(() => {
        logger.info('HTTP server closed');
        clearTimeout(forceClose);
        process.exit(0);
    });
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
