/**
 * Dynamic SOQL trap: the broken class compiles but fails at runtime on API 67.
 */
@IsTest
private class InvoiceDynamicQuery_Test {

    /**
     * Runs as the manager on purpose: the manager has every permission, so the
     * failure cannot be explained by FLS or sharing. It comes from the
     * WITH SECURITY_ENFORCED text inside the string. The expected platform message
     * says that SECURITY_ENFORCED is not supported on this API version; confirm the
     * exact text in your org and tighten the assert if you want.
     */
    @IsTest
    static void brokenFailsAtRuntime() {
        User gestor = TestPersonas.gestor();
        Id orderId = TestPersonas.seedOrderWithInvoices(UserInfo.getUserId());

        Boolean thrown = false;
        String message;
        System.runAs(gestor) {
            try {
                InvoiceDynamicQueryBroken.byOrder(orderId);
            } catch (Exception e) {
                thrown = true;
                message = e.getMessage();
            }
        }
        Assert.isTrue(thrown, 'Expected a runtime exception from WITH SECURITY_ENFORCED inside the string');
        Assert.isFalse(String.isBlank(message), 'The exception message should not be empty');
    }

    @IsTest
    static void fixedReturnsDataForGestor() {
        User gestor = TestPersonas.gestor();
        Id orderId = TestPersonas.seedOrderWithInvoices(UserInfo.getUserId());

        List<Invoice__c> rows;
        System.runAs(gestor) {
            rows = InvoiceDynamicQuery.byOrder(orderId);
        }
        Assert.areEqual(2, rows.size(), 'Manager should see both invoices');
    }

    @IsTest
    static void fixedThrowsQueryExceptionForVendedor() {
        User vendedor = TestPersonas.vendedor();
        Id orderId = TestPersonas.seedOrderWithInvoices(vendedor.Id);

        Boolean thrown = false;
        System.runAs(vendedor) {
            try {
                InvoiceDynamicQuery.byOrder(orderId);
            } catch (QueryException e) {
                thrown = true;
            }
        }
        Assert.isTrue(thrown, 'Seller has no FLS on Internal_Notes__c, USER_MODE must reject the query');
    }
}
