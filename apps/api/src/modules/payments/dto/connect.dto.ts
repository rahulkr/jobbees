import { ApiProperty } from '@nestjs/swagger';
import { ConnectStatus } from '@jobbees/prisma';

/** The hosted Stripe onboarding URL the tasker is sent to. */
export class ConnectOnboardingDto {
  @ApiProperty({ example: 'https://connect.stripe.com/setup/e/...' })
  url!: string;
}

/** Current Connect payout-onboarding state for the tasker. */
export class ConnectStatusDto {
  @ApiProperty({ enum: ConnectStatus })
  status!: ConnectStatus;

  @ApiProperty({ description: 'True once Stripe can pay the tasker out.' })
  payoutsEnabled!: boolean;

  @ApiProperty({ description: 'True once the tasker finished the Stripe form.' })
  detailsSubmitted!: boolean;
}
