import { Test, TestingModule } from "@nestjs/testing";
import { UsersController } from "./users.controller";
import { UsersService } from "./users.service";
import { CreateUserDto } from "./dto/create-user.dto";

describe("UsersController", () => {
  let controller: UsersController;
  let service: UsersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: {
            create: jest.fn((dto) => ({ id: "1", ...dto })),
            findAll: jest.fn(() => []),
            findOne: jest.fn((id) => ({
              id,
              name: "Test",
              email: "test@example.com",
            })),
            update: jest.fn((id, dto) => ({ id, ...dto })),
            remove: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<UsersController>(UsersController);
    service = module.get<UsersService>(UsersService);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });

  it("should create a user", () => {
    const dto: CreateUserDto = { name: "Test", email: "test@example.com" };
    expect(controller.create(dto)).toEqual({ id: "1", ...dto });
    expect(service.create).toHaveBeenCalledWith(dto);
  });

  it("should find all users", () => {
    controller.findAll();
    expect(service.findAll).toHaveBeenCalled();
  });
});
