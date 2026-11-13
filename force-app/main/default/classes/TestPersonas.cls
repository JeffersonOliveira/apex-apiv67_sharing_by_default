/**
 * Test factory for personas and seed data.
 *
 * Users and permission set assignments are created inside
 * System.runAs(new User(Id = UserInfo.getUserId())) to avoid the mixed DML error.
 * Every DML and query here names its access level, because on API 67 the
 * unannotated form follows user mode and this factory must not depend on that.
 */
@IsTest
public class TestPersonas {

    public static User vendedor() {
        return build('vendedor', 'Persona_Vendedor');
    }

    public static User gestor() {
        return build('gestor', 'Persona_Gestor');
    }

    public static User leitorNotas() {
        return build('leitor', 'Persona_Leitor_Notas');
    }

    /** Creates one Order__c owned by ownerId and returns its Id. */
    public static Id createOrder(Id ownerId) {
        Order__c o = new Order__c(
            Name = 'Order test',
            OwnerId = ownerId,
            Status__c = 'Draft',
            Total__c = 0
        );
        Database.insert(o, AccessLevel.SYSTEM_MODE);
        return o.Id;
    }

    /**
     * Creates one Order__c and two Invoice__c (100 and 50), one of them with
     * Internal_Notes__c = 'SECRET', all owned by ownerId. Returns the Order Id.
     */
    public static Id seedOrderWithInvoices(Id ownerId) {
        Id orderId = createOrder(ownerId);
        List<Invoice__c> invoices = new List<Invoice__c>{
            new Invoice__c(
                Name = 'INV-001',
                Order__c = orderId,
                OwnerId = ownerId,
                Total__c = 100,
                Status__c = 'Open',
                Internal_Notes__c = 'SECRET'
            ),
            new Invoice__c(
                Name = 'INV-002',
                Order__c = orderId,
                OwnerId = ownerId,
                Total__c = 50,
                Status__c = 'Open'
            )
        };
        Database.insert(invoices, AccessLevel.SYSTEM_MODE);
        return orderId;
    }

    private static User build(String persona, String permissionSetName) {
        Profile standardUser = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = :permissionSetName
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        String unique = String.valueOf(Math.abs(Crypto.getRandomLong()));
        User u = new User(
            FirstName = 'Persona',
            LastName = persona,
            Alias = persona.left(4) + unique.left(4),
            Email = 'persona.' + persona + '@v67.lab',
            Username = 'persona.' + persona + '.' + unique + '@v67.lab',
            ProfileId = standardUser.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Sao_Paulo'
        );

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Database.insert(u, AccessLevel.SYSTEM_MODE);
            Database.insert(
                new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id),
                AccessLevel.SYSTEM_MODE
            );
        }
        return u;
    }
}
