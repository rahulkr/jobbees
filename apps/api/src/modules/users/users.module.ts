import { Module } from '@nestjs/common';
import { TaskersController } from './taskers.controller';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  controllers: [UsersController, TaskersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
