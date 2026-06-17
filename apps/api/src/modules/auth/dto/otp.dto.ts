import { ApiProperty } from '@nestjs/swagger';
import { IsString, Length, Matches } from 'class-validator';

const PHONE_PATTERN = /^\+?[0-9]{8,15}$/;

export class OtpSendDto {
  @ApiProperty({ example: '+61400000000' })
  @IsString()
  @Matches(PHONE_PATTERN, { message: 'phone must be a valid E.164-style number' })
  phone!: string;
}

export class OtpVerifyDto {
  @ApiProperty({ example: '+61400000000' })
  @IsString()
  @Matches(PHONE_PATTERN, { message: 'phone must be a valid E.164-style number' })
  phone!: string;

  @ApiProperty({ example: '000000', description: 'Dev: any phone accepts 000000' })
  @IsString()
  @Length(6, 6)
  code!: string;
}
