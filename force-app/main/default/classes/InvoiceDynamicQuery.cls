/**
 * Fix for InvoiceDynamicQueryBroken.
 *
 * Database.queryWithBinds takes the access level as a parameter, so there is no
 * clause inside the string to forget. Binds come from the map, not from local
 * variables, which also removes string concatenation of values.
 */
public with sharing class InvoiceDynamicQuery {

    public static List<Invoice__c> byOrder(Id orderId) {
        String q = 'SELECT Id, Internal_Notes__c FROM Invoice__c '
            + 'WHERE Order__c = :orderId';
        return Database.queryWithBinds(
            q,
            new Map<String, Object>{ 'orderId' => orderId },
            AccessLevel.USER_MODE
        );
    }
}
