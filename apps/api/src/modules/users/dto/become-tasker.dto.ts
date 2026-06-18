import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '@jobbees/prisma';

/** Result of a client→tasker upgrade: the account's new role. */
export class BecomeTaskerResultDto {
  @ApiProperty({ enum: UserRole })
  role!: UserRole;
}
