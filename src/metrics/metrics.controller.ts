import { Controller, Get, Res } from "@nestjs/common";
import { Response } from "express";
import * as promClient from "prom-client";

@Controller("metrics")
export class MetricsController {
  @Get()
  async getMetrics(@Res() res: Response) {
    res.set("Content-Type", promClient.register.contentType);
    res.end(await promClient.register.metrics());
  }
}
