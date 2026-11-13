// Creates two persona users for manual demos:
//   persona.vendedor.<suffix>@v67.lab  -> Standard User + Persona_Vendedor
//   persona.gestor.<suffix>@v67.lab    -> Standard User + Persona_Gestor
// Run: sf apex run -f scripts/apex/setup-personas.apex -o lab
// The suffix keeps the username unique (usernames are unique across all orgs).

Profile standardUser = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
Map<String, PermissionSet> permsets = new Map<String, PermissionSet>();
for (PermissionSet ps : [
    SELECT Id, Name
    FROM PermissionSet
    WHERE Name IN ('Persona_Vendedor', 'Persona_Gestor')
]) {
    permsets.put(ps.Name, ps);
}
if (permsets.size() != 2) {
    throw new IllegalArgumentException('Deploy the permission sets first: sf project deploy start --source-dir force-app');
}

String suffix = String.valueOf(Math.abs(Crypto.getRandomLong())).left(6);
Map<String, String> personas = new Map<String, String>{
    'vendedor' => 'Persona_Vendedor',
    'gestor' => 'Persona_Gestor'
};

List<User> users = new List<User>();
for (String persona : personas.keySet()) {
    users.add(new User(
        FirstName = 'Persona',
        LastName = persona,
        Alias = persona.left(4) + suffix.left(4),
        Email = UserInfo.getUserEmail(),
        Username = 'persona.' + persona + '.' + suffix + '@v67.lab',
        ProfileId = standardUser.Id,
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        TimeZoneSidKey = 'America/Sao_Paulo'
    ));
}
insert users;

List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
for (User u : users) {
    String persona = u.LastName;
    assignments.add(new PermissionSetAssignment(
        AssigneeId = u.Id,
        PermissionSetId = permsets.get(personas.get(persona)).Id
    ));
}
insert assignments;

for (User u : users) {
    System.debug('Created ' + u.Username + ' (' + u.Id + ')');
}
