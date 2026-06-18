import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

const MAX_HOURLY_RATE_CENTS = 100_000; // $1,000/hr ceiling (sanity bound)

/** Partial update of the tasker profile; every field is optional. */
export class UpdateTaskerProfileDto {
  @ApiPropertyOptional({ maxLength: 1000 })
  @IsString()
  @MaxLength(1000)
  @IsOptional()
  bio?: string;

  @ApiPropertyOptional({ description: 'Hourly rate in cents (integer).' })
  @IsInt()
  @Min(0)
  @Max(MAX_HOURLY_RATE_CENTS)
  @IsOptional()
  hourlyRateCents?: number;

  @ApiPropertyOptional({ type: [String], description: 'Free-text skill tags.' })
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  @MaxLength(40, { each: true })
  @IsOptional()
  skills?: string[];
}

/** The tasker profile as returned to the owner. */
export class TaskerProfileDto {
  @ApiPropertyOptional({ nullable: true })
  bio!: string | null;

  @ApiPropertyOptional({ nullable: true })
  hourlyRateCents!: number | null;

  @ApiProperty({ type: [String] })
  skills!: string[];
}
