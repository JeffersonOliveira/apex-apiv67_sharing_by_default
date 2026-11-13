# apex-apiv67_sharing_by_default

Hands-on lab for the talk "API v67 sem sustos: USER_MODE, sharing por padrão e o playbook para migrar seu Apex" (Brazil Dreamin' 2026, November 13). It is a complete SFDX project with pairs of Apex classes (API 66 and API 67) that reproduce each scenario shown in the talk and in the two videos. The domain is generic: orders and invoices (`Order__c`, `Invoice__c`).

> **Important: *Broken* and *V66* classes are mirrors of the error.** `InvoiceQueryV66`, `InvoiceDynamicQueryBroken`, `InvoiceControllerBroken` and `InvoiceTriggerHandlerBroken` exist to show what goes wrong. Do not copy them into real code.

## What changes in API 67

These are the premises of the talk. **Verify each one in the release notes of your org**, because details can change between releases and between orgs.

1. `WITH SECURITY_ENFORCED` stops compiling. Use `WITH USER_MODE` (or `AccessLevel.USER_MODE` in dynamic SOQL).
2. Sharing becomes the default for a class. Write `with sharing`, `without sharing` or `inherited sharing` anyway.
3. SOQL and DML without an annotation follow user mode. Write the access level you mean.
4. The change is per class, driven by the `apiVersion` in its `.cls-meta.xml`. A class that stays on 66 keeps the old behavior.

Because the project must deploy even when an org does not reject `SECURITY_ENFORCED` on 67 yet, the "V66" classes sit at `apiVersion` 66.0 and the "V67" classes at 67.0. Video 1 is "copy the V66 class to a meta.xml with 67.0 and try to deploy".

## The playbook in four steps

**1. Inventory.** Find every place that will change. `SECURITY_ENFORCED` also hides inside strings, which the compiler does not read.

```bash
grep -rn "SECURITY_ENFORCED" force-app --include=*.cls --include=*.trigger
grep -rniE "database\.(query|countQuery)\(" force-app --include=*.cls
grep -rLE "(with|without|inherited) sharing" force-app --include=*.cls
grep -rnE "^\s*(insert|update|upsert|delete|undelete) " force-app --include=*.cls
grep -rn "apiVersion" force-app --include=*.cls-meta.xml
```

**2. Classify.** For each hit choose one: user mode by default, or system mode with a written justification (a comment such as `// gates:allow-system-mode: <reason>`).

**3. Migrate.** One class at a time. The persona test goes in the same pull request as the class.

**4. Regression.** Run the suite per persona before raising the version of the next class. Coverage is not proof: the test must run as the user who will use the code.

## Talk scenarios

| Talk scenario | Files | Command | Expected result |
|---|---|---|---|
| 1. Compile error (video 1) | `InvoiceQueryV66` | `./scripts/bump-api.sh InvoiceQueryV66` then `sf project deploy start --metadata ApexClass:InvoiceQueryV66 -o lab` | Deploy with 67.0 and `WITH SECURITY_ENFORCED` is rejected, pointing at the line. Deploy with 66.0 passes. |
| 2. Dynamic SOQL trap (video 2) | `InvoiceDynamicQueryBroken`, `InvoiceDynamicQuery`, `InvoiceDynamicQuery_Test` | `sf apex run -f scripts/apex/demo-dynamic-trap.apex -o lab` | Deploy passes, the Broken call fails at runtime, the fixed call works. |
| 3. USER_MODE is not a drop-in | `InvoiceQueryV66`, `InvoiceQueryV67`, `InvoiceQueryV66_Test`, `InvoiceQueryV67_Test` | `sf apex run test --class-names InvoiceQueryV66_Test --class-names InvoiceQueryV67_Test --result-format human --wait 10 -o lab` | V66 returns rows the reader does not own; V67 returns zero for the reader and a `QueryException` naming `Internal_Notes__c` for the seller. |
| 4. DML and controller guard | `InvoiceControllerBroken`, `InvoiceController`, `AccessGuard`, `InvoiceController_Test` | `sf apex run test --class-names InvoiceController_Test --result-format human --wait 10 -o lab` | Good version marks the invoice paid; Broken fails; the guard message names object and field. |
| 5. Trigger and async | `InvoiceTrigger`, `InvoiceTriggerHandler`, `InvoiceTriggerHandlerBroken`, `InvoiceRollupQueueable` and tests | `sf apex run test --class-names InvoiceTriggerHandler_Test --class-names InvoiceRollupQueueable_Test --result-format human --wait 10 -o lab` | 200 invoices roll up to the order with at most 5 queries; the Broken mirror fails for the restricted user; the job recalculates. |
| 6. Persona tests | `TestPersonas` and every `*_Test` class | `./scripts/run-tests.sh -o lab` | All tests pass. Read the asserts: each one states which persona and why. |

## Setup

```bash
git clone https://github.com/JeffersonOliveira/apex-apiv67_sharing_by_default.git
cd apex-apiv67_sharing_by_default
sf org login web -a lab
sf project deploy start --source-dir force-app -o lab
sf org assign permset --name Admin_Field_Access -o lab
sf apex run -f scripts/apex/setup-personas.apex -o lab
sf apex run -f scripts/apex/seed-data.apex -o lab
./scripts/run-tests.sh -o lab
```

Do not skip the `Admin_Field_Access` step. A source deploy grants no field-level security on new fields, not even to the admin, and on API 67 the tests and scripts read those fields in user mode. Without the permission set the suite fails with `Variable does not exist: tmpVar1`, a message that names neither the field nor the permission.

Use a Developer Edition or a scratch org (`config/project-scratch-def.json`). Do not use a production org. If the label "Order" or "Invoice" clashes with a standard object already enabled in your org, change the `<label>` in the two `.object-meta.xml` files; the API names do not change.

## Reproduce video 1: the compile error

1. Deploy the project (the V66 class passes at 66.0).
2. `./scripts/bump-api.sh InvoiceQueryV66` changes the class to 67.0.
3. `sf project deploy start --metadata ApexClass:InvoiceQueryV66 -o lab` and read the error.
4. Replace `WITH SECURITY_ENFORCED` by `WITH USER_MODE` in the class and deploy again: it passes.
5. Restore: `./scripts/bump-api.sh InvoiceQueryV66 --revert` and put the original query back (`git checkout -- force-app/main/default/classes/InvoiceQueryV66.cls`).

## Reproduce video 2: the dynamic SOQL trap

1. `sf apex run -f scripts/apex/demo-dynamic-trap.apex -o lab`: the Broken call fails at runtime although its deploy passed.
2. `sf apex run test --class-names InvoiceDynamicQuery_Test --result-format human --wait 10 -o lab`: the tests show Broken failing and the fixed version working per persona.

## Exercise

The hands-on lab of November 24 (Salesforce Developer Group Rio de Janeiro) builds on this project. Its exercise sheet will be added to this repository for the event. If you find a break pattern that this project does not cover, open an issue with the template "padrão de quebra encontrado" (org anonymized, version, snippet, fix).

## Further reading

Official Salesforce links to go deeper into the topics of this playbook.

**Trailhead**

- [Data Security](https://trailhead.salesforce.com/content/learn/modules/data_security): module on object, field and record access, the basis of the CRUD, FLS and sharing checks that user mode enforces.
- [Apex Basics & Database](https://trailhead.salesforce.com/content/learn/modules/apex_database): module on DML, SOQL and SOSL in Apex, the operations whose default mode changes in API 67.
- [Apex Testing](https://trailhead.salesforce.com/content/learn/modules/apex_testing): module on Apex unit tests, the starting point for writing persona tests.
- [Keep Data Secure in a Recruiting App](https://trailhead.salesforce.com/content/learn/projects/keep-data-secure-in-a-recruiting-app): hands-on project with profiles, field-level security, permission sets and sharing settings.
- [Quick Start: Explore the Apex Recipes Sample App](https://trailhead.salesforce.com/content/learn/projects/quick-start-explore-the-apex-recipes-sample-app): project that installs the Apex Recipes sample app, with SOQL queries that respect CRUD and FLS.
- [Develop Secure Web Apps](https://trailhead.salesforce.com/content/learn/trails/security_developer): trail on secure development on the platform: configuration, client-side code and secrets storage.

**Reference documentation**

- Apex Developer Guide
  - [Set an Access Mode for Database Operations](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_enforce_usermode.htm): how to declare user mode or system mode in SOQL, SOSL, DML and the `Database` methods.
  - [Use the with sharing, without sharing, and inherited sharing Keywords](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_keywords_sharing.htm): what each sharing keyword does and what the default is when a class declares none.
  - [Enforce Security with the stripInaccessible Method](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexref/apex_classes_with_security_stripInaccessible.htm): how to strip inaccessible fields from a query result or before DML with `Security.stripInaccessible`.
  - [Dynamic SOQL](https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-dynamic-soql.html): queries built at runtime, including `Database.queryWithBinds`.
- Apex Reference Guide
  - [AccessLevel Class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_AccessLevel.htm): reference for `AccessLevel.USER_MODE` and `AccessLevel.SYSTEM_MODE`.
  - [Database Class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm): signatures of the `Database` methods, including `queryWithBinds`, with the access level parameter.
  - [System Class](https://developer.salesforce.com/docs/platform/apex-ref/references/apex-ref/apex-methods-system-system.html): reference for `System.runAs`, used in the persona tests.
  - [Apex Versioned Behavior Changes](https://developer.salesforce.com/docs/platform/apex-ref/references/apex-ref/versioned-behavior-changes.html): what changes in behavior in each API version, including 67.0.
- Summer '26 release notes, the release that introduced API 67.0
  - [Database Operations Run in User Mode by Default, Not System Mode](https://help.salesforce.com/s/articleView?id=release-notes.rn_apex_default_user_mode.htm&language=en_US&release=262&type=5): announces user mode as the default for SOQL, SOSL, DML and `Database` methods.
  - [Apex Classes Enforce Sharing Rules by Default](https://help.salesforce.com/s/articleView?id=release-notes.rn_apex_default_enforce_sharing.htm&language=en_US&release=262&type=5): announces `with sharing` as the default for a class with no sharing declaration.
  - [The WITH SECURITY_ENFORCED SOQL Clause is Removed](https://help.salesforce.com/s/articleView?id=release-notes.rn_apex_removed_withSecurityEnforced.htm&language=en_US&release=262&type=5): announces that the clause no longer compiles and points to `WITH USER_MODE`.
  - [Apex Triggers Always Run in a “without sharing” Context](https://help.salesforce.com/s/articleView?id=release-notes.rn_apex_triggers_system_mode.htm&language=en_US&release=262&type=5): covers triggers, whose database operations also follow user mode.

## License

MIT. See [`LICENSE`](LICENSE).

---

## Resumo em português

Este repositório acompanha a palestra "API v67 sem sustos" do Brazil Dreamin' 2026. Ele reproduz, em pares de classes, o que muda ao subir o Apex para a API 67: WITH SECURITY_ENFORCED deixa de compilar, o sharing passa a ser o padrão da classe e SOQL e DML sem anotação seguem o user mode.
A mudança vale por classe, pela apiVersion do meta.xml. Por isso as classes V66 ficam em 66.0 e as V67 em 67.0.
O playbook tem quatro passos: inventário (busca textual, inclusive dentro de strings), classificação (user mode por padrão, system mode só com justificativa), migração classe a classe e regressão com testes de persona.
Os testes rodam como um vendedor restrito, um gestor e um leitor sem acesso aos registros, para provar o comportamento de verdade e não apenas a cobertura.
As classes *Broken e *V66 são espelhos do erro: não copie para código real.
Confira sempre as release notes da sua org, porque os detalhes podem mudar.
O exercício do Laboratório de 24/11 será publicado neste repositório para o evento.
Use uma Developer Edition ou scratch org, nunca produção.
