import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '@jobbees/prisma';

/** Result of a self-service role change (become-tasker / switch-to-client): the account's new role. */
export class RoleResultDto {
  @ApiProperty({ enum: UserRole })
  role!: UserRole;
}
