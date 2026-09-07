import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { FindOptionsWhere, Repository } from 'typeorm';
import { CreateTaskDto } from './dto/create-task.dto';
import { TaskQueryDto } from './dto/task-query.dto';
import { TaskResponseDto } from './dto/task-response.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { Task } from './entities/task.entity';
import { TaskStatus } from './enums/task-status.enum';

@Injectable()
export class TasksService {
  constructor(
    @InjectRepository(Task)
    private readonly tasksRepository: Repository<Task>,
  ) {}

  async create(
    userId: string,
    createTaskDto: CreateTaskDto,
  ): Promise<TaskResponseDto> {
    const task = this.tasksRepository.create({
      ...createTaskDto,
      description: createTaskDto.description ?? null,
      status: createTaskDto.status ?? TaskStatus.TODO,
      userId,
    });
    return TaskResponseDto.fromEntity(await this.tasksRepository.save(task));
  }

  async findAll(
    userId: string,
    query: TaskQueryDto,
  ): Promise<TaskResponseDto[]> {
    const where: FindOptionsWhere<Task> = { userId };
    if (query.status) {
      where.status = query.status;
    }

    const tasks = await this.tasksRepository.find({
      where,
      order: { createdAt: 'DESC' },
    });
    return tasks.map((task) => TaskResponseDto.fromEntity(task));
  }

  async findOne(userId: string, id: string): Promise<TaskResponseDto> {
    return TaskResponseDto.fromEntity(await this.findOwnedTask(userId, id));
  }

  async update(
    userId: string,
    id: string,
    updateTaskDto: UpdateTaskDto,
  ): Promise<TaskResponseDto> {
    const task = await this.findOwnedTask(userId, id);
    this.tasksRepository.merge(task, updateTaskDto);
    return TaskResponseDto.fromEntity(await this.tasksRepository.save(task));
  }

  async remove(userId: string, id: string): Promise<void> {
    const task = await this.findOwnedTask(userId, id);
    await this.tasksRepository.remove(task);
  }

  private async findOwnedTask(userId: string, id: string): Promise<Task> {
    const task = await this.tasksRepository.findOne({ where: { id, userId } });
    if (!task) {
      throw new NotFoundException('Task not found');
    }
    return task;
  }
}
