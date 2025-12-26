import { Controller, Get } from '@nestjs/common';
import * as packageJson from '../package.json';

@Controller()
export class AppController {

    @Get()
    getHello(): any {
        return { message: 'Hello from the Gold Standard Pipeline. Success simulation 8' };
    }

    @Get('health')
    getHealth(): any {
        return { status: 'UP', timestamp: new Date() };
    }

    @Get('version')
    getVersion(): any {
        return {
            version: packageJson.version,
            name: packageJson.name,
            description: packageJson.description,
        };
    }
}
