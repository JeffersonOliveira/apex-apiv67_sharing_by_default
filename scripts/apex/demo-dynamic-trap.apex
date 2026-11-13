// Video 2: the dynamic SOQL trap.
// The deploy of InvoiceDynamicQueryBroken passed. The error only shows up here, at runtime.
// Run: sf apex run -f scripts/apex/demo-dynamic-trap.apex -o lab
// Requires seed data: sf apex run -f scripts/apex/seed-data.apex -o lab

List<Order__c> orders = [SELECT Id FROM Order__c LIMIT 1];
if (orders.isEmpty()) {
    throw new IllegalArgumentException('No Order__c found. Run scripts/apex/seed-data.apex first.');
}
Id orderId = orders[0].Id;

System.debug('--- BROKEN: WITH SECURITY_ENFORCED inside a string ---');
try {
    List<Invoice__c> broken = InvoiceDynamicQueryBroken.byOrder(orderId);
    System.debug('Unexpected: no error, rows = ' + broken.size());
} catch (Exception e) {
    System.debug(LoggingLevel.ERROR, 'Runtime error: ' + e.getTypeName() + ': ' + e.getMessage());
}

System.debug('--- FIXED: queryWithBinds + AccessLevel.USER_MODE ---');
try {
    List<Invoice__c> fixed = InvoiceDynamicQuery.byOrder(orderId);
    System.debug('Rows = ' + fixed.size());
} catch (Exception e) {
    System.debug(LoggingLevel.ERROR, 'Runtime error: ' + e.getTypeName() + ': ' + e.getMessage());
}
