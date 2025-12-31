import "./profiler"; // Must be the very first import to hook into the process
import sdk from "./tracing";
import { AppLoggerService } from "./logger/logger.service";

console.log("Tracing initialized:", !!sdk); // Must be first
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import helmet from "helmet";

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    bufferLogs: true, // Buffer logs until logger is attached
  });
  app.useLogger(app.get(AppLoggerService));
  app.enableShutdownHooks(); // Essential for K8s graceful shutdown

  app.enableCors();

  // Custom Helmet logic or use nestjs-helmet if preferred
  // For now simple express usage
  app.use(helmet());

  await app.listen(3000);
  const logger = app.get(AppLoggerService);
  logger.log(`Application is running on: ${await app.getUrl()}`, "Bootstrap");
}
bootstrap();
