import { ConflictException, NotFoundException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { UsersService } from './users.service';

describe('UsersService', () => {
  let repository: jest.Mocked<Repository<User>>;
  let service: UsersService;

  const userId = '04d3c56c-10f5-4bca-8e8a-cf1309e2a278';
  const now = new Date('2026-09-21T12:00:00.000Z');

  function makeUser(overrides: Partial<User> = {}): User {
    return {
      id: userId,
      email: 'user@example.com',
      displayName: null,
      bio: null,
      passwordHash: 'password-hash',
      tasks: [],
      createdAt: now,
      updatedAt: now,
      ...overrides,
    };
  }

  beforeEach(() => {
    repository = {
      create: jest.fn(),
      save: jest.fn(),
      findOne: jest.fn(),
      merge: jest.fn(),
    } as unknown as jest.Mocked<Repository<User>>;
    service = new UsersService(repository);
  });

  it('updates editable profile fields and returns a safe response', async () => {
    const user = makeUser();
    const updatedUser = makeUser({
      email: 'updated@example.com',
      displayName: 'Ada Lovelace',
      bio: 'Building reliable APIs.',
    });
    repository.findOne.mockResolvedValue(user);
    repository.merge.mockReturnValue(updatedUser);
    repository.save.mockResolvedValue(updatedUser);

    const result = await service.updateProfile(userId, {
      email: 'updated@example.com',
      displayName: 'Ada Lovelace',
      bio: 'Building reliable APIs.',
    });

    expect(repository.merge).toHaveBeenCalledWith(user, {
      email: 'updated@example.com',
      displayName: 'Ada Lovelace',
      bio: 'Building reliable APIs.',
    });
    expect(result).toEqual({
      id: userId,
      email: 'updated@example.com',
      displayName: 'Ada Lovelace',
      bio: 'Building reliable APIs.',
      createdAt: now,
      updatedAt: now,
    });
    expect(result).not.toHaveProperty('passwordHash');
  });

  it('returns not found when the authenticated user no longer exists', async () => {
    repository.findOne.mockResolvedValue(null);

    await expect(
      service.updateProfile(userId, { displayName: 'Ada Lovelace' }),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(repository.save).not.toHaveBeenCalled();
  });

  it('maps a duplicate email constraint violation to conflict', async () => {
    repository.findOne.mockResolvedValue(makeUser());
    repository.save.mockRejectedValue(
      Object.assign(new Error('duplicate key'), { code: '23505' }),
    );

    await expect(
      service.updateProfile(userId, { email: 'taken@example.com' }),
    ).rejects.toBeInstanceOf(ConflictException);
  });
});
