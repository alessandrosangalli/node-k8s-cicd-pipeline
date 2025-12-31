const SERVICE_NAME = process.env.OTEL_SERVICE_NAME || 'node-k8s-service';
const VERSION = process.env.npm_package_version || '1.0.0';
const PROJECT_ID = process.env.GCP_PROJECT_ID; // Optional: Force a specific project

async function startProfiler() {
    // Bypassa o profiler se estivermos rodando testes ou se explicitamente desativado
    if (process.env.NODE_ENV === 'test' || process.env.DISABLE_PROFILER === 'true') {
        return;
    }

    try {
        // Dynamic import to avoid crash if the binary is missing (common in Windows dev without build tools)
        // using require because import() is async and we want to catch module resolution errors safely
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const profiler = require('@google-cloud/profiler');

        await profiler.start({
            projectId: PROJECT_ID, // If undefined, it will auto-discover from GKE metadata/ADC
            serviceContext: {
                service: SERVICE_NAME,
                version: VERSION,
            },
            logLevel: 2, // Log warnings and errors
        });
        console.log(`Google Cloud Profiler started for service: ${SERVICE_NAME}`);
    } catch (err) {
        // Fail gracefully.
        // 1. Missing Binary (Visual C++ missing on Windows) -> MODULE_NOT_FOUND
        // 2. Missing Credentials (Local Dev) -> Error
        console.warn(
            'Google Cloud Profiler skipped. This is expected in local development if binaries or credentials are missing.\n',
            `Reason: ${err.message}`
        );
    }
}

startProfiler();
