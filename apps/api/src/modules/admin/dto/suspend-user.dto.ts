import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class SuspendUserDto {
  @ApiPropertyOptional({
    description: 'Reason recorded on the user + in the audit log.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
