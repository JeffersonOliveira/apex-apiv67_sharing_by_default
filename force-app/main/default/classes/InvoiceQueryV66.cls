/**
 * MIRROR OF THE ERROR (API 66). Do not copy this pattern into new code.
 *
 * This class stays at apiVersion 66.0 on purpose. It has no sharing keyword and
 * uses WITH SECURITY_ENFORCED. Talk scenario 1: copy this class to a meta.xml
 * with apiVersion 67.0 (scripts/bump-api.sh InvoiceQueryV66) and try to deploy.
 * Verify the exact behavior in the release notes of your org.
 */
public class InvoiceQueryV66 {

    public static List<Invoice__c> byOrder(Id orderId) {
        return [
            SELECT Id, Total__c, Internal_Notes__c
            FROM Invoice__c
            WHERE Order__c = :orderId
            WITH SECURITY_ENFORCED
        ];
    }
}
