/**
 * @description       : ContactTypeDebtBatch Class
 * @author            : Horizon CX
 * @last modified on  : 12/08/2025
 * @last modified by  : Horizon CX
 *      - 14/10/2025  : Una deuda con un Phone (que no sea un móvil no será considera "Phone + Email"
**/
global class ContactTypeDebtBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //Se cogen las Debts que estan en estado "Open"
        return Database.getQueryLocator([
            SELECT Id
            FROM Debt__c
            WHERE Status_SEL__c = 'Open'
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Debt__c> debts) {
        Set<Id> debtIds = new Set<Id>();
        for (Debt__c d : debts) {
            debtIds.add(d.Id);
        }

        // Traer Contact Data relacionados. Solo los validos y contactables
        List<ContactData__c> contactDataList = [
            SELECT Id, Debt_REL__c, ContactDataType_SEL__c
            FROM ContactData__c
            WHERE Debt_REL__c IN :debtIds
            AND IsValid__c = TRUE AND IsContactable__c = TRUE
        ];

        // Agrupar los Contact Data por Debt
        Map<Id, Set<String>> typesByDebt = new Map<Id, Set<String>>();
        for (ContactData__c cd : contactDataList) {
            if (!typesByDebt.containsKey(cd.Debt_REL__c)) {
                typesByDebt.put(cd.Debt_REL__c, new Set<String>());
            }
            typesByDebt.get(cd.Debt_REL__c).add(cd.ContactDataType_SEL__c);
        }

        // Preparar deudas para actualizar
        List<Debt__c> debtsToUpdate = new List<Debt__c>();

        for (Debt__c d : debts) {
            Set<String> dataTypes = typesByDebt.get(d.Id);
            if (dataTypes == null || dataTypes.isEmpty()) continue;

            String contactType;

            Boolean hasEmail = dataTypes.contains('Email');
            Boolean hasPhone = dataTypes.contains('Phone');
            Boolean hasMobile = dataTypes.contains('MobilePhone');

            if (hasEmail && hasMobile) {
                contactType = 'Phone + Email';
            } else if (hasEmail && !hasPhone && !hasMobile) {
                contactType = 'Only Email';
            } else if (hasPhone && !hasEmail && !hasMobile) {
                contactType = 'Only Phone';
            } /*else if (hasMobile && !hasEmail && !hasPhone) {
                contactType = 'Only MobilePhone';
            } */else {
                contactType = 'No Contact Data';
            }

            d.ContactType__c = contactType;
            debtsToUpdate.add(d);
        }

        if (!debtsToUpdate.isEmpty()) {
            update debtsToUpdate;
        }
    }
    global void finish(Database.BatchableContext bc) {
        System.debug('ContactTypeDebtBatch completed successfully.');
    }
}