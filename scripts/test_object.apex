List<Schema.SObjectType> allObjects = Schema.getGlobalDescribe().values();
for(Schema.SObjectType obj : allObjects) {
    String name = obj.getDescribe().getName();
    if(name.containsIgnoreCase('segment') || name.containsIgnoreCase('market')) {
        System.debug(name);
    }
}
