/**
 * Guard that proves permissions before a system mode write.
 *
 * Both methods check every listed field first and then the object, and throw
 * AccessDeniedException naming the object and the field that is missing, so a
 * controller can turn it into an actionable message.
 */
public with sharing class AccessGuard {

    public class AccessDeniedException extends Exception {
        public String objectName;
        public String fieldName;
    }

    public static void requireUpdateable(SObjectType objType, List<SObjectField> fields) {
        DescribeSObjectResult objDescribe = objType.getDescribe();
        for (SObjectField f : fields) {
            DescribeFieldResult fieldDescribe = f.getDescribe();
            if (!fieldDescribe.isUpdateable()) {
                throw denied('edit', objDescribe, fieldDescribe);
            }
        }
        if (!objDescribe.isUpdateable()) {
            throw denied('edit', objDescribe, null);
        }
    }

    public static void requireAccessible(SObjectType objType, List<SObjectField> fields) {
        DescribeSObjectResult objDescribe = objType.getDescribe();
        for (SObjectField f : fields) {
            DescribeFieldResult fieldDescribe = f.getDescribe();
            if (!fieldDescribe.isAccessible()) {
                throw denied('read', objDescribe, fieldDescribe);
            }
        }
        if (!objDescribe.isAccessible()) {
            throw denied('read', objDescribe, null);
        }
    }

    private static AccessDeniedException denied(
        String action,
        DescribeSObjectResult objDescribe,
        DescribeFieldResult fieldDescribe
    ) {
        String target = objDescribe.getLabel();
        if (fieldDescribe != null) {
            target += '.' + fieldDescribe.getLabel();
        }
        AccessDeniedException ex = new AccessDeniedException('You cannot ' + action + ' ' + target + '.');
        ex.objectName = objDescribe.getName();
        ex.fieldName = fieldDescribe == null ? null : fieldDescribe.getName();
        return ex;
    }
}
