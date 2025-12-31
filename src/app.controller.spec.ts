import { Test, TestingModule } from "@nestjs/testing";
import { AppController } from "./app.controller";

describe("AppController", () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe("root", () => {
    it("should return a greeting message", () => {
      expect(appController.getHello()).toEqual({
        message: "Hello from the Gold Standard Pipeline. Success simulation 9",
      });
    });
  });

  describe("health", () => {
    it("should return UP status", () => {
      expect(appController.getHealth()).toEqual({
        status: "UP",
        timestamp: expect.any(Date),
      });
    });
  });
});
