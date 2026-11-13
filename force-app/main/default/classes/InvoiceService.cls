/**
 * Thin service used by the persona test slide ("Testes com persona").
 * It reads in user mode, so the caller's sharing and FLS apply.
 */
public with sharing class InvoiceService {

    public static List<Invoice__c> summarize(List<Id> orderIds) {
        return [
            SELECT Id, Total__c, Internal_Notes__c
            FROM Invoice__c
            WHERE Order__c IN :orderIds
            WITH USER_MODE
        ];
    }
}
