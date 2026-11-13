/**
 * Documents the OLD behavior of InvoiceQueryV66 (API 66, no sharing keyword).
 *
 * The test class is explicitly "without sharing" so that the class under test,
 * which declares nothing, inherits a known sharing context.
 */
@IsTest
private without sharing class InvoiceQueryV66_Test {

    /**
     * On API 66, with private sharing and a class that has no sharing keyword, this
     * returns rows the user should not see: the reader owns nothing and has no view
     * all, yet gets the rows. SECURITY_ENFORCED only checked CRUD and FLS.
     */
    @IsTest
    static void documentsOldBehavior() {
        User leitor = TestPersonas.leitorNotas();
        Id orderId = TestPersonas.seedOrderWithInvoices(UserInfo.getUserId());

        List<Invoice__c> rows;
        System.runAs(leitor) {
            rows = InvoiceQueryV66.byOrder(orderId);
        }
        // Documents current behavior (size > 0). The V67 test asserts the opposite.
        Assert.isTrue(rows.size() > 0, 'API 66 class without sharing returns rows the user does not own');
    }

    /** SECURITY_ENFORCED already checked FLS: the seller has no access to Internal_Notes__c. */
    @IsTest
    static void securityEnforcedStillChecksFls() {
        User vendedor = TestPersonas.vendedor();
        Id orderId = TestPersonas.seedOrderWithInvoices(vendedor.Id);

        Boolean thrown = false;
        System.runAs(vendedor) {
            try {
                InvoiceQueryV66.byOrder(orderId);
            } catch (QueryException e) {
                thrown = true;
            }
        }
        Assert.isTrue(thrown, 'Expected a QueryException for the missing FLS on Internal_Notes__c');
    }
}
