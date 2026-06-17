-- AuditLog is append-only (CLAUDE.md rule 7 / security-review skill §I2;
-- closes scope-reconciliation gap #27).
--
-- Defence in depth:
--   1. REVOKE UPDATE/DELETE from PUBLIC — takes effect once the app connects as
--      a non-owner role (Sprint 10 / Key Vault). It is a no-op for the table
--      owner, which is why we also add a hard trigger guard below.
--   2. A BEFORE UPDATE/DELETE trigger that always raises — enforced regardless
--      of role or table ownership, so even the owner (today's single dev/CI
--      role) cannot mutate or delete audit rows. INSERT + SELECT still work.

REVOKE UPDATE, DELETE ON "AuditLog" FROM PUBLIC;

CREATE OR REPLACE FUNCTION jobbees_auditlog_append_only()
  RETURNS trigger
  LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'AuditLog is append-only: % is not permitted', TG_OP
    USING ERRCODE = 'insufficient_privilege';
END;
$$;

CREATE TRIGGER auditlog_block_update
  BEFORE UPDATE ON "AuditLog"
  FOR EACH ROW EXECUTE FUNCTION jobbees_auditlog_append_only();

CREATE TRIGGER auditlog_block_delete
  BEFORE DELETE ON "AuditLog"
  FOR EACH ROW EXECUTE FUNCTION jobbees_auditlog_append_only();
