import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { User } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  let authService: AuthService;
  let usersService: jest.Mocked<UsersService>;
  let jwtService: jest.Mocked<JwtService>;

  const now = new Date('2026-09-07T12:00:00.000Z');

  function makeUser(passwordHash: string): User {
    return {
      id: '04d3c56c-10f5-4bca-8e8a-cf1309e2a278',
      email: 'user@example.com',
      passwordHash,
      tasks: [],
      createdAt: now,
      updatedAt: now,
    };
  }

  beforeEach(() => {
    usersService = {
      findByEmail: jest.fn(),
      create: jest.fn(),
    } as unknown as jest.Mocked<UsersService>;
    jwtService = {
      signAsync: jest.fn(),
    } as unknown as jest.Mocked<JwtService>;
    authService = new AuthService(usersService, jwtService);
  });

  it('hashes a password and returns a safe user on registration', async () => {
    usersService.findByEmail.mockResolvedValue(null);
    usersService.create.mockImplementation((_email, passwordHash) =>
      Promise.resolve(makeUser(passwordHash)),
    );

    const result = await authService.register({
      email: 'user@example.com',
      password: 'a-secure-password',
    });

    expect(result).toEqual({
      id: expect.any(String),
      email: 'user@example.com',
      createdAt: now,
      updatedAt: now,
    });
    const savedHash = usersService.create.mock.calls[0][1];
    expect(savedHash).not.toBe('a-secure-password');
    await expect(argon2.verify(savedHash, 'a-secure-password')).resolves.toBe(
      true,
    );
  });

  it('rejects duplicate registration before hashing', async () => {
    usersService.findByEmail.mockResolvedValue(makeUser('existing-hash'));

    await expect(
      authService.register({
        email: 'user@example.com',
        password: 'a-secure-password',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(usersService.create).not.toHaveBeenCalled();
  });

  it('issues a JWT for valid credentials', async () => {
    const passwordHash = await argon2.hash('a-secure-password');
    const user = makeUser(passwordHash);
    usersService.findByEmail.mockResolvedValue(user);
    jwtService.signAsync.mockResolvedValue('signed.jwt.token');

    const result = await authService.login({
      email: user.email,
      password: 'a-secure-password',
    });

    expect(jwtService.signAsync).toHaveBeenCalledWith({
      sub: user.id,
      email: user.email,
    });
    expect(result.accessToken).toBe('signed.jwt.token');
    expect(result.user).not.toHaveProperty('passwordHash');
  });

  it('returns the same generic error for missing users and bad passwords', async () => {
    usersService.findByEmail.mockResolvedValueOnce(null);
    await expect(
      authService.login({
        email: 'missing@example.com',
        password: 'wrong-password',
      }),
    ).rejects.toThrow(new UnauthorizedException('Invalid email or password'));

    const passwordHash = await argon2.hash('a-secure-password');
    usersService.findByEmail.mockResolvedValueOnce(makeUser(passwordHash));
    await expect(
      authService.login({
        email: 'user@example.com',
        password: 'wrong-password',
      }),
    ).rejects.toThrow(new UnauthorizedException('Invalid email or password'));
  });
});
