import { Module, MiddlewareConsumer, RequestMethod } from "@nestjs/common";
import { AppController } from "./app.controller";
import { MetricsController } from "./metrics/metrics.controller";
import { MetricsMiddleware } from "./metrics/metrics.middleware";

import { LoggerModule } from "./logger/logger.module";

import { RequestLoggingMiddleware } from "./logger/request-logging.middleware";

@Module({
  imports: [LoggerModule],
  controllers: [AppController, MetricsController],
  providers: [],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(RequestLoggingMiddleware, MetricsMiddleware)
      .forRoutes({ path: "*", method: RequestMethod.ALL });
  }
}
