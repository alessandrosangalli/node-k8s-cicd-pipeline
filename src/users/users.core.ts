import { User } from "./entities/user.entity";
import { CreateUserDto } from "./dto/create-user.dto";
import { UpdateUserDto } from "./dto/update-user.dto";
import { randomUUID } from "crypto";

// Functional Core: Pure functions, immutable data transformations

export const createUser = (
  users: User[],
  dto: CreateUserDto,
): { nextState: User[]; user: User } => {
  const user: User = {
    id: randomUUID(),
    ...dto,
  };
  return { nextState: [...users, user], user };
};

export const findUserById = (users: User[], id: string): User | undefined => {
  return users.find((u) => u.id === id);
};

export const updateUser = (
  users: User[],
  id: string,
  dto: UpdateUserDto,
): { nextState: User[]; user: User | null } => {
  const index = users.findIndex((u) => u.id === id);
  if (index === -1) {
    return { nextState: users, user: null };
  }

  const updatedUser = { ...users[index], ...dto };
  const nextState = [...users];
  nextState[index] = updatedUser;

  return { nextState, user: updatedUser };
};

export const removeUser = (
  users: User[],
  id: string,
): { nextState: User[]; success: boolean } => {
  const index = users.findIndex((u) => u.id === id);
  if (index === -1) {
    return { nextState: users, success: false };
  }

  const nextState = [...users];
  nextState.splice(index, 1);
  return { nextState, success: true };
};
