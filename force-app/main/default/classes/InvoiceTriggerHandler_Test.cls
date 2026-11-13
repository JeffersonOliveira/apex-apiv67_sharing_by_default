/**
 * Trigger tests. The seller saves 200 invoices for one order (created by the
 * seller, so ownership gives access). The rollup must be correct and bulk safe.
 *
 * To reproduce the break by hand: change the call in InvoiceTrigger to
 * InvoiceTriggerHandlerBroken.afterSave(Trigger.new) and run this class again.
 */
@IsTest
private class InvoiceTriggerHandler_Test {

    @IsTest
    static void bulkSaveRollsUpWithFewQueries() {
        User vendedor = TestPersonas.vendedor();
        Id orderId = TestPersonas.createOrder(vendedor.Id);

        List<Invoice__c> rows = new List<Invoice__c>();
        for (Integer i = 0; i < 200; i++) {
            rows.add(new Invoice__c(
                Name = 'INV-' + i,
                Order__c = orderId,
                Total__c = 10,
                Status__c = 'Open'
            ));
        }

        Integer queries;
        Test.startTest();
        System.runAs(vendedor) {
            insert as user rows;
            queries = Limits.getQueries();
        }
        Test.stopTest();

        Assert.isTrue(queries <= 5, 'Expected at most 5 queries, got ' + queries);

        Order__c o = [
            SELECT Total__c
            FROM Order__c
            WHERE Id = :orderId
            WITH SYSTEM_MODE
        ];
        Decimal expected = 2000;
        Assert.isTrue(o.Total__c == expected, 'Expected rollup 2000, got ' + o.Total__c);
    }

    /**
     * The Broken handler uses plain SOQL and DML. On API 67 those follow user mode,
     * and the seller has read only access to Order.Total__c, so the write fails.
     */
    @IsTest
    static void brokenMirrorFailsForRestrictedUser() {
        User vendedor = TestPersonas.vendedor();
        Id orderId = TestPersonas.createOrder(vendedor.Id);
        Invoice__c inv = new Invoice__c(
            Name = 'INV-X',
            Order__c = orderId,
            OwnerId = vendedor.Id,
            Total__c = 100,
            Status__c = 'Open'
        );
        Database.insert(inv, AccessLevel.SYSTEM_MODE);

        Boolean thrown = false;
        System.runAs(vendedor) {
            try {
                InvoiceTriggerHandlerBroken.afterSave(new List<Invoice__c>{ inv });
            } catch (Exception e) {
                thrown = true;
            }
        }
        Assert.isTrue(thrown, 'Expected the user mode update of Order.Total__c to fail for the seller');
    }
}
