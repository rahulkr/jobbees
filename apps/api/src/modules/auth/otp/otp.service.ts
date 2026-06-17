/**
 * Phone-OTP provider contract. The dev implementation is MockOtpService; the
 * real provider (Firebase/Notifyre/Twilio) is chosen in Sprint 5 (ADR 008) and
 * bound to this same token, so consumers never change.
 */
export abstract class OtpService {
  abstract send(phone: string): Promise<void>;
  abstract verify(phone: string, code: string): Promise<boolean>;
}
