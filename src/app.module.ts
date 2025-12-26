import { Module, MiddlewareConsumer, RequestMethod } from "@nestjs/common";
import { AppController } from "./app.controller";
import { MetricsController } from "./metrics/metrics.controller";
import { MetricsMiddleware } from "./metrics/metrics.middleware";

@Module({
  imports: [],
  controllers: [AppController, MetricsController],
  providers: [],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(MetricsMiddleware)
      .forRoutes({ path: "*", method: RequestMethod.ALL });
  }
}
