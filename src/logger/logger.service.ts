import { Injectable, LoggerService } from "@nestjs/common";
import * as winston from "winston";
import { context, trace } from "@opentelemetry/api";

@Injectable()
export class AppLoggerService implements LoggerService {
  private logger: winston.Logger;

  constructor() {
    // Custom format to inject trace_id and span_id
    const injectTraceId = winston.format((info) => {
      const currentSpan = trace.getSpan(context.active());
      if (currentSpan) {
        const spanContext = currentSpan.spanContext();
        info.trace_id = spanContext.traceId;
        info.span_id = spanContext.spanId;
        info.trace_flags = spanContext.traceFlags;
      }
      return info;
    });

    // List of sensitive keys to redact
    const SENSITIVE_KEYS = [
      "password",
      "token",
      "authorization",
      "cookie",
      "secret",
      "credit_card",
      "apikey",
    ];

    // Native Replacer function for JSON serialization
    const replacer = (key: string, value: any) => {
      // Check if key corresponds to a sensitive field
      if (key && SENSITIVE_KEYS.includes(key.toLowerCase())) {
        return "[REDACTED]";
      }
      return value;
    };

    // Development Pretty Print Format
    const devFormat = winston.format.printf(
      ({ timestamp, level, message, context, trace_id, ...meta }) => {
        const ctx = context ? `[${context}]` : "";
        const trace = trace_id ? `| Trace: ${trace_id}` : "";
        const metaString = Object.keys(meta).length
          ? `\n${JSON.stringify(meta, replacer, 2)}`
          : "";

        return `${timestamp} ${level} ${ctx}: ${message} ${trace}${metaString}`;
      },
    );

    this.logger = winston.createLogger({
      level: process.env.LOG_LEVEL || "info",
      format: winston.format.combine(
        injectTraceId(),
        winston.format.timestamp({ format: "HH:mm:ss" }),
        winston.format.json({ replacer }),
      ),
      defaultMeta: { service: "node-k8s-service" },
      transports: [
        new winston.transports.Console({
          format:
            process.env.NODE_ENV === "production"
              ? winston.format.json({ replacer })
              : winston.format.combine(
                  winston.format.colorize(),
                  winston.format.simple(), // Required for colorize to work properly with printf
                  devFormat,
                ),
        }),
      ],
    });
  }

  log(message: any, ...optionalParams: any[]) {
    this.logger.info(message, { context: this.getContext(optionalParams) });
  }

  error(message: any, ...optionalParams: any[]) {
    this.logger.error(message, { context: this.getContext(optionalParams) });
  }

  warn(message: any, ...optionalParams: any[]) {
    this.logger.warn(message, { context: this.getContext(optionalParams) });
  }

  debug?(message: any, ...optionalParams: any[]) {
    this.logger.debug(message, { context: this.getContext(optionalParams) });
  }

  verbose?(message: any, ...optionalParams: any[]) {
    this.logger.verbose(message, { context: this.getContext(optionalParams) });
  }

  private getContext(params: any[]): string {
    if (params.length > 0) {
      return params[params.length - 1]; // NestJS usually passes context as the last arg
    }
    return "System";
  }
}
