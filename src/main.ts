import sdk from './tracing';

console.log('Tracing initialized:', !!sdk); // Must be first
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
    const app = await NestFactory.create(AppModule);

    app.enableCors();

    // Custom Helmet logic or use nestjs-helmet if preferred
    // For now simple express usage
    const helmet = require('helmet');
    app.use(helmet());

    await app.listen(3000);
    console.log(`Application is running on: ${await app.getUrl()}`);
}
bootstrap();
