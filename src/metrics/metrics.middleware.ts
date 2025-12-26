import { Injectable, NestMiddleware } from "@nestjs/common";
import { Request, Response, NextFunction } from "express";
import * as promClient from "prom-client";

// Initialize Prometheus metrics once
const collectDefaultMetrics = promClient.collectDefaultMetrics;
collectDefaultMetrics();

const requestCounter = new promClient.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status"],
});

const httpRequestDurationMicroseconds = new promClient.Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status"],
  buckets: [0.1, 0.5, 1, 1.5, 2, 5],
});

@Injectable()
export class MetricsMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const end = httpRequestDurationMicroseconds.startTimer();
    res.on("finish", () => {
      requestCounter.inc({
        method: req.method,
        route: req.baseUrl + req.path, // NestJS routing path
        status: res.statusCode,
      });
      end({
        method: req.method,
        route: req.baseUrl + req.path,
        status: res.statusCode,
      });
    });
    next();
  }
}
