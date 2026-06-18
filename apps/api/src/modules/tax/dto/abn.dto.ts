import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, Matches } from 'class-validator';

export class SubmitAbnDto {
  @ApiProperty({
    example: '51824753556',
    description: '11-digit ABN; spaces allowed. Checksum is validated server-side.',
  })
  @IsString()
  // Loose shape only (11 digits, optional spaces). The real checksum check is
  // AbnValidator in the service, which returns a precise 400 on failure.
  @Matches(/^[0-9\s]{11,14}$/, { message: 'abn must be 11 digits' })
  abn!: string;
}

export class AbnStatusDto {
  @ApiPropertyOptional({ description: 'The stored ABN, or null if not set.' })
  abn!: string | null;

  @ApiPropertyOptional({ description: 'Business/entity name from the ABR.' })
  businessName!: string | null;

  @ApiPropertyOptional({
    description: 'When the ABN was confirmed active via the ABR (null = unverified).',
  })
  verifiedAt!: Date | null;
}
