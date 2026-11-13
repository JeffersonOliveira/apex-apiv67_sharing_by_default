/**
 * Persona tests for InvoiceQueryV67 and InvoiceService (API 67, USER_MODE).
 */
@IsTest
private class InvoiceQueryV67_Test {

    /** Seller owns the data but has no FLS on Internal_Notes__c: USER_MODE rejects the query. */
    @IsTest
    static void vendedorGetsQueryException() {
        User vendedor = TestPersonas.vendedor();
        Id orderId = TestPersonas.seedOrderWithInvoices(vendedor.Id);

        Boolean thrown = false;
        System.runAs(vendedor) {
            try {
                InvoiceQueryV67.byOrder(orderId);
                Assert.fail('Expected QueryException');
            } catch (QueryException e) {
                thrown = true;
                // Expected platform message names the inaccessible field.
                Assert.isTrue(e.getMessage().contains('Internal_Notes__c'), e.getMessage());
            }
        }
        Assert.isTrue(thrown, 'The QueryException was not raised');
    }

    /** Manager has view all and FLS: the data comes back. */
    @IsTest
    static void gestorGetsRows() {
        User gestor = TestPersonas.gestor();
        Id orderId = TestPersonas.seedOrderWithInvoices(UserInfo.getUserId());

        List<Invoice__c> rows;
        System.runAs(gestor) {
            rows = InvoiceQueryV67.byOrder(orderId);
        }
        Assert.areEqual(2, rows.size(), 'Manager should see both invoices');
    }

    /**
     * USER_MODE is not a drop-in: sharing now applies. The reader has FLS on every
     * field but owns nothing and has no view all, so the same data returns zero rows.
     * Compare with InvoiceQueryV66_Test.documentsOldBehavior.
     */
    @IsTest
    static void sharingNowApplies() {
        User leitor = TestPersonas.leitorNotas();
        Id orderId = TestPersonas.seedOrderWithInvoices(UserInfo.getUserId());

        List<Invoice__c> rows;
        System.runAs(leitor) {
            rows = InvoiceQueryV67.byOrder(orderId);
        }
        Assert.areEqual(0, rows.size(), 'Reader must not see rows owned by someone else');
    }

    /** Mirrors the slide "Testes com persona". */
    @IsTest
    static void slideExample() {
        User vendedor = TestPersonas.vendedor();
        Id orderId = TestPersonas.seedOrderWithInvoices(vendedor.Id);
        List<Id> ids = new List<Id>{ orderId };

        System.runAs(vendedor) {
            try {
                InvoiceService.summarize(ids);
                Assert.fail('Esperava QueryException');
            } catch (QueryException e) {
                Assert.isTrue(e.getMessage().contains('Internal_Notes__c'));
            }
        }
        System.runAs(TestPersonas.gestor()) {
            Assert.isFalse(InvoiceService.summarize(ids).isEmpty());
        }
    }
}
