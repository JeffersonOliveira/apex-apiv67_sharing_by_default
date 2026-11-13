/**
 * Async version of the rollup.
 *
 * Jobs run as the user who enqueued them, including users deactivated later.
 * That is why a denial is logged before the exception is rethrown: without the
 * log, a failure at night is silent.
 */
public with sharing class InvoiceRollupQueueable implements Queueable {

    private final Set<Id> orderIds;

    public InvoiceRollupQueueable(Set<Id> orderIds) {
        this.orderIds = orderIds;
    }

    public void execute(QueueableContext context) {
        try {
            if (orderIds == null || orderIds.isEmpty()) {
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

            // gates:allow-system-mode: rollup must succeed regardless of the enqueuing user's FLS on Order.Total__c
            Database.update(orders, AccessLevel.SYSTEM_MODE);
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Rollup denied for user ' + UserInfo.getUserName() + ': ' + e.getMessage()
            );
            throw e;
        }
    }
}
