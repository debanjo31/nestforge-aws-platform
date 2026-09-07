import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CreateTaskDto } from './dto/create-task.dto';
import { TaskQueryDto } from './dto/task-query.dto';
import { TaskResponseDto } from './dto/task-response.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { TaskStatus } from './enums/task-status.enum';
import { TasksService } from './tasks.service';

@ApiTags('Tasks')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard)
@Controller('tasks')
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Post()
  @ApiOperation({ summary: 'Create a task owned by the authenticated user' })
  @ApiResponse({ status: 201, type: TaskResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid request payload' })
  @ApiResponse({ status: 401, description: 'Missing or invalid JWT' })
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() createTaskDto: CreateTaskDto,
  ): Promise<TaskResponseDto> {
    return this.tasksService.create(user.id, createTaskDto);
  }

  @Get()
  @ApiOperation({ summary: 'List only the authenticated user’s tasks' })
  @ApiQuery({ name: 'status', required: false, enum: TaskStatus })
  @ApiResponse({ status: 200, type: TaskResponseDto, isArray: true })
  @ApiResponse({ status: 400, description: 'Invalid status filter' })
  @ApiResponse({ status: 401, description: 'Missing or invalid JWT' })
  findAll(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: TaskQueryDto,
  ): Promise<TaskResponseDto[]> {
    return this.tasksService.findAll(user.id, query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get one task owned by the authenticated user' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, type: TaskResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid task UUID' })
  @ApiResponse({ status: 404, description: 'Task not found for this user' })
  findOne(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ): Promise<TaskResponseDto> {
    return this.tasksService.findOne(user.id, id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a task owned by the authenticated user' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, type: TaskResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid UUID or request payload' })
  @ApiResponse({ status: 404, description: 'Task not found for this user' })
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() updateTaskDto: UpdateTaskDto,
  ): Promise<TaskResponseDto> {
    return this.tasksService.update(user.id, id, updateTaskDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a task owned by the authenticated user' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 204, description: 'Task deleted' })
  @ApiResponse({ status: 400, description: 'Invalid task UUID' })
  @ApiResponse({ status: 404, description: 'Task not found for this user' })
  remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ): Promise<void> {
    return this.tasksService.remove(user.id, id);
  }
}
