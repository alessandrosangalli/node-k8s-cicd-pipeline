import { Test, TestingModule } from "@nestjs/testing";
import { UsersService } from "./users.service";
import { NotFoundException } from "@nestjs/common";

describe("UsersService", () => {
  let service: UsersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [UsersService],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  it("should create a user", () => {
    const user = service.create({
      name: "Test User",
      email: "test@example.com",
    });
    expect(user).toHaveProperty("id");
    expect(user.name).toBe("Test User");
    expect(service.findAll()).toHaveLength(1);
  });

  it("should find all users", () => {
    service.create({ name: "User 1", email: "1@example.com" });
    service.create({ name: "User 2", email: "2@example.com" });
    expect(service.findAll()).toHaveLength(2);
  });

  it("should find one user by id", () => {
    const created = service.create({ name: "Test", email: "test@example.com" });
    const found = service.findOne(created.id);
    expect(found).toEqual(created);
  });

  it("should throw error if user not found", () => {
    expect(() => service.findOne("invalid-id")).toThrow(NotFoundException);
  });

  it("should update a user", () => {
    const created = service.create({ name: "Old", email: "old@example.com" });
    const updated = service.update(created.id, { name: "New" });
    expect(updated.name).toBe("New");
    expect(updated.email).toBe("old@example.com");
  });

  it("should remove a user", () => {
    const created = service.create({
      name: "To Delete",
      email: "del@example.com",
    });
    service.remove(created.id);
    expect(service.findAll()).toHaveLength(0);
  });
});
