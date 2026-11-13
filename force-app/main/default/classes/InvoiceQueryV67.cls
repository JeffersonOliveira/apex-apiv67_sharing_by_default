/**
 * API 67 version of InvoiceQueryV66.
 *
 * Same query, but sharing is explicit and the query runs in user mode.
 * USER_MODE is not a drop-in replacement for SECURITY_ENFORCED: it also applies
 * record sharing, checks FLS in WHERE and ORDER BY, and reports all violations.
 */
public with sharing class InvoiceQueryV67 {

    public static List<Invoice__c> byOrder(Id orderId) {
        return [
            SELECT Id, Total__c, Internal_Notes__c
            FROM Invoice__c
            WHERE Order__c = :orderId
            WITH USER_MODE
        ];
    }
}
