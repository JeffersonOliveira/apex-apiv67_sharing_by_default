/**
 * Controller tests: the guard version works and explains itself, the broken
 * version fails because it writes a field the persona cannot edit.
 */
@IsTest
private class InvoiceController_Test {

    private static Id firstInvoiceId(Id orderId) {
        return [
            SELECT Id
            FROM Invoice__c
            WHERE Order__c = :orderId
            WITH SYSTEM_MODE
            ORDER BY Name
            LIMIT 1
        ].Id;
    }

    /** The seller has edit FLS on Invoice.Status, so the guard passes and the write happens. */
    @IsTest
    static void vendedorCanMarkPaid() {
        User vendedor = TestPersonas.vendedor();
        Id orderId = TestPersonas.seedOrderWithInvoices(vendedor.Id);
        Id invoiceId = firstInvoiceId(orderId);

        System.runAs(vendedor) {
            InvoiceController.markPaid(invoiceId);
        }

        Invoice__c after = [
            SELECT Status__c
            FROM Invoice__c
            WHERE Id = :invoiceId
            WITH SYSTEM_MODE
        ];
        Assert.areEqual('Paid', after.Status__c);
    }

    /** The broken version also writes Internal_Notes__c, which the seller cannot edit. */
    @IsTest
    static void brokenFailsForVendedor() {
        User vendedor = TestPersonas.vendedor();
        Id orderId = TestPersonas.seedOrderWithInvoices(vendedor.Id);
        Id invoiceId = firstInvoiceId(orderId);

        Boolean thrown = false;
        System.runAs(vendedor) {
            try {
                InvoiceControllerBroken.markPaid(invoiceId);
            } catch (DmlException e) {
                thrown = true;
            } catch (AuraHandledException e) {
                thrown = true;
            }
        }
        Assert.isTrue(thrown, 'Expected DmlException: the seller cannot edit Internal_Notes__c');
    }

    /** A reader without edit access gets a message with object and field, no stack trace. */
    @IsTest
    static void guardGivesActionableMessage() {
        User leitor = TestPersonas.leitorNotas();
        Id orderId = TestPersonas.seedOrderWithInvoices(UserInfo.getUserId());
        Id invoiceId = firstInvoiceId(orderId);

        Boolean thrown = false;
        String message;
        System.runAs(leitor) {
            try {
                InvoiceController.markPaid(invoiceId);
            } catch (AuraHandledException e) {
                thrown = true;
                message = e.getMessage();
            }
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException');
        Assert.isTrue(message.contains('Invoice.Status'), message);
        Assert.isTrue(message.contains('Ask your admin'), message);
    }
}
