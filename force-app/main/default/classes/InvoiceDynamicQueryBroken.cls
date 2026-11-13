/**
 * MIRROR OF THE ERROR (dynamic SOQL trap). Do not copy this pattern.
 *
 * This compiles on API 67 because the compiler does not read what is inside a
 * string. The problem only shows up at runtime, when the query runs: on API 67
 * the platform does not support WITH SECURITY_ENFORCED, so the call fails in the
 * user's save, not in your deploy. Verify the exact error in your org.
 */
public with sharing class InvoiceDynamicQueryBroken {

    public static List<Invoice__c> byOrder(Id orderId) {
        String q = 'SELECT Id, Internal_Notes__c FROM Invoice__c '
            + 'WHERE Order__c = :orderId '
            + 'WITH SECURITY_ENFORCED';
        return Database.query(q);
    }
}
