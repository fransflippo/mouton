public with sharing class MigrationSelector {
    
    public List<Migration__c> selectMigrationsByPackageNameAndVersion(String packageName, List<Integer> versions) {
        return [ 
                SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c, Status__c
                FROM Migration__c 
                WHERE 
                    Package__c = :packageName AND 
                    Version__c IN :versions
                ORDER BY Version__c
        ];
    }

    public List<Migration__c> selectMigrationsByPackageNameAndId(String packageName, List<Id> ids) {
        return [
                SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c, Status__c
                FROM Migration__c
                WHERE
                    Package__c = :packageName AND
                    Id IN :ids
                ORDER BY Version__c
        ];
    }

    public List<Migration__c> selectMigrationsByPackageName(String packageName) {
        return [ 
                SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c, Status__c 
                FROM Migration__c 
                WHERE 
                        Package__c = :packageName
                ORDER BY Version__c
        ];
    }

    public List<Migration__c> selectMigrationsByPackageNameAndStatus(String packageName, List<String> statuses) {
        return [
                SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c, Status__c
                FROM Migration__c
                WHERE
                        Package__c = :packageName AND
                        Status__c IN :statuses
                ORDER BY Version__c
                        
        ];
    }

    public List<String> selectUniquePackages() {
        List<AggregateResult> migrations = [ SELECT Package__c FROM Migration__c GROUP BY Package__c ];
        List<String> packages = new List<String>();
        for (AggregateResult migration : migrations) {
            packages.add((String) migration.get('m7n__Package__c'));
        }
        return packages;
    }

}