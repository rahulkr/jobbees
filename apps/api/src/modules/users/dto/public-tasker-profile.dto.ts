import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/** Which trust signals a tasker has cleared (rendered as badges). */
export class TaskerVerifiedBadgesDto {
  @ApiProperty()
  email!: boolean;

  @ApiProperty()
  phone!: boolean;

  @ApiProperty({ description: 'Stripe Connect payout onboarding complete.' })
  payments!: boolean;
}

/**
 * A tasker's profile as seen by clients. Deliberately a narrow projection — no
 * email, phone, ABN number, or bank details (security-review E4).
 */
export class PublicTaskerProfileDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  firstName!: string;

  @ApiPropertyOptional({ nullable: true })
  avatarUrl!: string | null;

  @ApiPropertyOptional({ nullable: true })
  bio!: string | null;

  @ApiPropertyOptional({ nullable: true })
  hourlyRateCents!: number | null;

  @ApiPropertyOptional({ nullable: true, description: 'ABR business name.' })
  businessName!: string | null;

  @ApiProperty({ type: [String] })
  skills!: string[];

  @ApiProperty({ type: TaskerVerifiedBadgesDto })
  verified!: TaskerVerifiedBadgesDto;
}
