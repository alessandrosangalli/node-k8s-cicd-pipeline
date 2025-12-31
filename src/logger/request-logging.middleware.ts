import { Injectable, NestMiddleware, Logger } from "@nestjs/common";
import { Request, Response, NextFunction } from "express";

@Injectable()
export class RequestLoggingMiddleware implements NestMiddleware {
  private readonly logger = new Logger("HTTP");

  use(req: Request, res: Response, next: NextFunction) {
    const start = Date.now();
    const { method, originalUrl, ip } = req;
    const userAgent = req.get("user-agent") || "";

    res.on("finish", () => {
      const { statusCode } = res;
      const duration = Date.now() - start;

      this.logger.log({
        message: `${method} ${originalUrl} ${statusCode} - ${duration}ms`,
        method,
        url: originalUrl,
        statusCode,
        duration,
        ip,
        userAgent,
      });
    });

    next();
  }
}
