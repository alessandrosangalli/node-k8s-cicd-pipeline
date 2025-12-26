import sdk from "./tracing";

console.log("Tracing initialized:", !!sdk); // Must be first
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import helmet from "helmet";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.enableCors();

  // Custom Helmet logic or use nestjs-helmet if preferred
  // For now simple express usage
  // For now simple express usage
  app.use(helmet());

  await app.listen(3000);
  console.log(`Application is running on: ${await app.getUrl()}`);
}
bootstrap();
