/**
 * Read as the user, write as the system, but only after the guard.
 *
 * 1. Guard: prove the user can read and edit the fields we are about to touch.
 * 2. Read in USER_MODE: the user only sees the records and fields they may see.
 * 3. Write with SYSTEM_MODE: the guard already proved the permission for the
 *    fields we write, so the write cannot silently exceed the user's rights.
 * 4. Failure becomes an actionable message (object and field), never a stack trace.
 */
public with sharing class InvoiceController {

    @AuraEnabled
    public static void markPaid(Id invoiceId) {
        try {
            List<SObjectField> touched = new List<SObjectField>{ Invoice__c.Status__c };
            AccessGuard.requireAccessible(Invoice__c.SObjectType, touched);
            AccessGuard.requireUpdateable(Invoice__c.SObjectType, touched);

            List<Invoice__c> rows = [
                SELECT Id, Status__c
                FROM Invoice__c
                WHERE Id = :invoiceId
                WITH USER_MODE
                LIMIT 1
            ];
            if (rows.isEmpty()) {
                throw fail('Invoice not found or not shared with you.');
            }

            Invoice__c inv = rows[0];
            inv.Status__c = 'Paid';
            // gates:allow-system-mode: the guard above proved edit access to Invoice.Status
            Database.update(inv, AccessLevel.SYSTEM_MODE);
        } catch (AccessGuard.AccessDeniedException e) {
            throw fail(e.getMessage() + ' Ask your admin for the Vendedor permission set.');
        }
    }

    private static AuraHandledException fail(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        // Without setMessage, getMessage() returns "Script-thrown exception".
        ex.setMessage(message);
        return ex;
    }
}
