/**
 * MIRROR OF THE ERROR (DML in a controller). Do not copy this pattern.
 *
 * It writes Internal_Notes__c with "update as user". A user without edit FLS on
 * that field (Persona Vendedor) gets a generic failure at runtime, with no hint
 * about which object or field is missing. See InvoiceController for the fix.
 */
public with sharing class InvoiceControllerBroken {

    @AuraEnabled
    public static void markPaid(Id invoiceId) {
        Invoice__c inv = [
            SELECT Id, Status__c
            FROM Invoice__c
            WHERE Id = :invoiceId
            LIMIT 1
        ];
        inv.Status__c = 'Paid';
        inv.Internal_Notes__c = 'paid by ' + UserInfo.getName();
        update as user inv;
    }
}
