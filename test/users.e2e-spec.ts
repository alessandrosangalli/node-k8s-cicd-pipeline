import { Test, TestingModule } from "@nestjs/testing";
import { INestApplication, ValidationPipe } from "@nestjs/common";
import * as request from "supertest";
import { AppModule } from "./../src/app.module";

describe("UsersController (e2e)", () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it("/users (POST) should create user", async () => {
    const response = await request(app.getHttpServer())
      .post("/users")
      .send({ name: "E2E User", email: "e2e@example.com" })
      .expect(201);

    expect(response.body).toHaveProperty("id");
    expect(response.body.name).toBe("E2E User");
  });

  it("/users (POST) should fail with invalid data", async () => {
    await request(app.getHttpServer())
      .post("/users")
      .send({ name: "" }) // Missing email, empty name
      .expect(400);
  });
});
