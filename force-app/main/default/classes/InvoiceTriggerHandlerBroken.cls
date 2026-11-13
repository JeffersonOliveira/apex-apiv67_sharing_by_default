/**
 * MIRROR OF THE ERROR (trigger handler). Do not copy this pattern.
 *
 * Same logic as InvoiceTriggerHandler, but with plain SOQL and plain DML and no
 * access level written down. On API 67 this runs in user mode, so the save of a
 * restricted user fails on Order.Total__c (the rollup field is read only for
 * Persona Vendedor). Nothing in the code says that this is intentional.
 *
 * InvoiceTrigger does NOT call this class. To see the break, change the call in
 * InvoiceTrigger to InvoiceTriggerHandlerBroken.afterSave(Trigger.new), deploy,
 * and save invoices as Persona Vendedor. See the README, scenario 5.
 */
public with sharing class InvoiceTriggerHandlerBroken {

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
            GROUP BY Order__c
        ]) {
            Decimal sumTotal = (Decimal) ar.get('sumTotal');
            totals.put((Id) ar.get('ord'), sumTotal == null ? 0 : sumTotal);
        }

        List<Order__c> orders = [
            SELECT Id, Total__c
            FROM Order__c
            WHERE Id IN :orderIds
        ];
        for (Order__c o : orders) {
            o.Total__c = totals.get(o.Id);
        }

        update orders;
    }
}
