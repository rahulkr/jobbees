/**
 * Transactional email contract. Dev uses MockMailService; SendGrid is wired in
 * Sprint 5/8. Consumers depend on this token, not the implementation.
 */
export abstract class MailService {
  abstract sendEmailVerification(email: string, token: string): Promise<void>;
  abstract sendPasswordReset(email: string, token: string): Promise<void>;
}
