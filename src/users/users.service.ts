import { Injectable, NotFoundException } from "@nestjs/common";
import { CreateUserDto } from "./dto/create-user.dto";
import { UpdateUserDto } from "./dto/update-user.dto";
import { User } from "./entities/user.entity";
import { createUser, findUserById, removeUser, updateUser } from "./users.core";

@Injectable()
export class UsersService {
  // Imperative Shell: Manages state (mutable) and side-effects (exceptions)
  private users: User[] = [];

  create(createUserDto: CreateUserDto): User {
    const result = createUser(this.users, createUserDto);
    this.users = result.nextState;
    return result.user;
  }

  findAll(): User[] {
    return this.users;
  }

  findOne(id: string): User {
    const user = findUserById(this.users, id);
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return user;
  }

  update(id: string, updateUserDto: UpdateUserDto): User {
    const result = updateUser(this.users, id, updateUserDto);
    if (!result.user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    this.users = result.nextState;
    return result.user;
  }

  remove(id: string): void {
    const result = removeUser(this.users, id);
    if (!result.success) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    this.users = result.nextState;
  }
}
