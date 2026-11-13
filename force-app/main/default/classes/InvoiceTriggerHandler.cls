/**
 * Rolls up Invoice__c.Total__c into Order__c.Total__c after every save.
 *
 * Reads run as the user (USER_MODE). The write is explicit SYSTEM_MODE because
 * the rollup must succeed regardless of the saver's FLS on Order.Total__c.
 * Bulk safe: two queries and one DML for any number of invoices.
 */
public with sharing class InvoiceTriggerHandler {

    public static void afterSave(List<Invoice__c> invoices) {
        Set<Id> orderIds = new Set<Id>();
        for (Invoice__c inv : invoices) {
            if (inv.Order__c != null) {
                orderIds.add(inv.Order__c);
            }
        }
        if (orderIds.isEmpty()) {
            return;
        }

        Map<Id, Decimal> totals = new Map<Id, Decimal>();
        for (Id orderId : orderIds) {
            totals.put(orderId, 0);
        }

        for (AggregateResult ar : [
            SELECT Order__c ord, SUM(Total__c) sumTotal
            FROM Invoice__c
            WHERE Order__c IN :orderIds
            WITH USER_MODE
            GROUP BY Order__c
        ]) {
            Decimal sumTotal = (Decimal) ar.get('sumTotal');
            totals.put((Id) ar.get('ord'), sumTotal == null ? 0 : sumTotal);
        }

        List<Order__c> orders = [
            SELECT Id, Total__c
            FROM Order__c
            WHERE Id IN :orderIds
            WITH USER_MODE
        ];
        for (Order__c o : orders) {
            o.Total__c = totals.get(o.Id);
        }

        // gates:allow-system-mode: rollup must succeed regardless of the saver's FLS on Order.Total__c
        Database.update(orders, AccessLevel.SYSTEM_MODE);
    }
}
