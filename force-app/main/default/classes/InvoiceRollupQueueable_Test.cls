@IsTest
private class InvoiceRollupQueueable_Test {

    @IsTest
    static void jobRecalculatesOrderTotal() {
        Id orderId = TestPersonas.seedOrderWithInvoices(UserInfo.getUserId());

        // The trigger already rolled up on seed. Reset the total so the job has work to do.
        Database.update(new Order__c(Id = orderId, Total__c = 0), AccessLevel.SYSTEM_MODE);

        Test.startTest();
        System.enqueueJob(new InvoiceRollupQueueable(new Set<Id>{ orderId }));
        Test.stopTest();

        Order__c o = [
            SELECT Total__c
            FROM Order__c
            WHERE Id = :orderId
            WITH SYSTEM_MODE
        ];
        Decimal expected = 150;
        Assert.isTrue(o.Total__c == expected, 'Expected rollup 150, got ' + o.Total__c);
    }
}
