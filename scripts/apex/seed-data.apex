// Seeds one Order__c and two Invoice__c owned by the current user.
// One invoice has Internal_Notes__c = 'SECRET'.
// Run: sf apex run -f scripts/apex/seed-data.apex -o lab

Id me = UserInfo.getUserId();

Order__c ord = new Order__c(
    Name = 'Order demo',
    OwnerId = me,
    Status__c = 'Draft',
    Total__c = 0
);
insert ord;

List<Invoice__c> invoices = new List<Invoice__c>{
    new Invoice__c(
        Name = 'INV-DEMO-001',
        Order__c = ord.Id,
        OwnerId = me,
        Total__c = 100,
        Status__c = 'Open',
        Internal_Notes__c = 'SECRET'
    ),
    new Invoice__c(
        Name = 'INV-DEMO-002',
        Order__c = ord.Id,
        OwnerId = me,
        Total__c = 50,
        Status__c = 'Open'
    )
};
insert invoices;

System.debug('Order Id: ' + ord.Id);
for (Invoice__c inv : invoices) {
    System.debug('Invoice Id: ' + inv.Id + ' (' + inv.Name + ')');
}
