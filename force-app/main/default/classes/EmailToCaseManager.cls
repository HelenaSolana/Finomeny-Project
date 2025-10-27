/**
 * @description       : EmailToCaseManager Class
 * @author            : Horizon CX
 * @last modified on  : 02/09/2025
 * @last modified by  : Horizon CX
 *  30/09/2025        : Añadido nuevo buzon de EmailToCase
**/
public with sharing class EmailToCaseManager {

    public static void processEmails(List<EmailMessage> newRecords) {
        List<Case> casesToInsert = new List<Case>();
        List<Case> casesToUpdate = new List<Case>();
        
        Set<String> fromAddresses = new Set<String>();
        Set<String> toAddresses   = new Set<String>();
        Set<Id> relatedCaseIds = new Set<Id>();

        Map<String, Account> emailToAccountMap = new Map<String, Account>();
        Map<String, ContactData__c> emailToContactDataMap = new Map<String, ContactData__c>();
        Map<Id, List<DebtCustomer__c>> accountToDebtsMap = new Map<Id, List<DebtCustomer__c>>();
        Map<Id, Case> existingCasesMap = new Map<Id, Case>();

        Set<Id> customerIdsAcc = new Set<Id>();
        Set<Id> customerIdsCData = new Set<Id>();
        Map<String, Id> mailboxToQueueMap = new Map<String, Id>();

        Boolean emailCase;

        // 1. Recoger todos los emails de origen
        for (EmailMessage em : newRecords) {
                if (em.FromAddress != null) fromAddresses.add(em.FromAddress.toLowerCase());
                if (em.ToAddress != null)   toAddresses.add(em.ToAddress.toLowerCase());
                if (em.RelatedToId != null) relatedCaseIds.add(em.RelatedToId);
                emailCase = em.Incoming;

        }
    
        System.debug('fromAddresses: ' + fromAddresses);
        System.debug('toAddresses: ' + toAddresses);
        System.debug('emailCase: ' + emailCase);

        if (emailCase == false) {
            return;
        }

        if (!relatedCaseIds.isEmpty()) {
            for (Case c : [SELECT Id, AccountId, ContactId, Debt_REL__c FROM Case WHERE Id IN :relatedCaseIds]) {
                existingCasesMap.put(c.Id, c);
            }
        }

        // 2. Buscar Customer (PersonAccount) por PersonEmail
        for (Account acc : [
            SELECT Id, PersonEmail, PersonContactId
            FROM Account 
            WHERE PersonEmail IN :fromAddresses
        ]) {
            System.debug('acc: ' + acc);
            if (acc.PersonEmail != null) {
                emailToAccountMap.put(acc.PersonEmail.toLowerCase(), acc);
            }
        }
        System.debug('emailToAccountMap: ' + emailToAccountMap);

        // 3. Si no encuentra el Customer por el PersonEmail se miran los registros de ContactData para encontrar el Customer relacionado
        if (emailToAccountMap.isEmpty()) {
            for (ContactData__c cd : [
                SELECT Id, ContactDataValue__c, Customer_REL__c, Customer_REL__r.PersonContactId
                FROM ContactData__c 
                WHERE ContactDataType_SEL__c = 'Email' AND ContactDataValue__c IN :fromAddresses
            ]) {
                System.debug('cd: ' + cd);
                if (cd.ContactDataValue__c != null) {
                    emailToContactDataMap.put(cd.ContactDataValue__c.toLowerCase(), cd);
                }
            }
            System.debug('emailToContactDataMap: ' + emailToContactDataMap);
        } 

        // 4. Buscar deudas relacionadas con los Customer, si lo encuentra
        for (Account acc : emailToAccountMap.values()) {
            customerIdsAcc.add(acc.Id);
        }
        for (ContactData__c data : emailToContactDataMap.values()) {
            customerIdsCData.add(data.Customer_REL__c);
        }

        if (!customerIdsAcc.isEmpty()) {
            for (DebtCustomer__c dc : [
                SELECT Id, Debt_REL__c, Customer_REL__c, Debt_REL__r.Status_SEL__c
                FROM DebtCustomer__c
                WHERE Customer_REL__c IN : customerIdsAcc AND Debt_REL__r.Status_SEL__c = 'Open'
            ]) {
                System.debug('dc: ' + dc);
                if (!accountToDebtsMap.containsKey(dc.Customer_REL__c)) {
                    accountToDebtsMap.put(dc.Customer_REL__c, new List<DebtCustomer__c>());
                }
                accountToDebtsMap.get(dc.Customer_REL__c).add(dc);
            }
        }else if(!customerIdsCData.isEmpty()){
            for (DebtCustomer__c dc : [
                SELECT Id, Debt_REL__c, Customer_REL__c, Debt_REL__r.Status_SEL__c
                FROM DebtCustomer__c
                WHERE Customer_REL__c IN : customerIdsCData AND Debt_REL__r.Status_SEL__c = 'Open'
            ]) {
                System.debug('dc: ' + dc);
                if (!accountToDebtsMap.containsKey(dc.Customer_REL__c)) {
                    accountToDebtsMap.put(dc.Customer_REL__c, new List<DebtCustomer__c>());
                }
                accountToDebtsMap.get(dc.Customer_REL__c).add(dc);
            }
        }

        // 5. Buscar colas para cada buzón (ToAddress)
        for (Group g : [
            SELECT Id, DeveloperName 
            FROM Group 
            WHERE Type = 'Queue'
              AND DeveloperName IN ('Support_EmailCase', 'Privacy_EmailCase')
        ]) {
            System.debug('g: ' + g);
            mailboxToQueueMap.put(g.DeveloperName.toLowerCase(), g.Id);
        }

        // 6. Procesar cada EmailMessage
        for (EmailMessage em : newRecords) {
            System.debug('emailToAccountMap.get(em.FromAddress != null ? em.FromAddress.toLowerCase() : null);  '+emailToAccountMap.get(em.FromAddress != null ? em.FromAddress.toLowerCase() : null));
            Account acc = emailToAccountMap.get(em.FromAddress != null ? em.FromAddress.toLowerCase() : null);
            ContactData__c contactData = emailToContactDataMap.get(em.FromAddress != null ? em.FromAddress.toLowerCase() : null);
            
            Case c;
            if (em.RelatedToId != null && existingCasesMap.containsKey(em.RelatedToId)) {
                // Actualizar caso existente
                c = existingCasesMap.get(em.RelatedToId);
            }else {
                // Crear caso nuevo
                c = new Case();
                c.Subject           = (em.Subject != null && em.Subject != '') ? em.Subject : 'Caso creado por Email ' + em.FromAddress;
                c.Description       = (em.TextBody != null && em.TextBody != '') ? em.TextBody : 'Sin contenido';
                c.Origin            = 'Email';
                c.CaseOrigin_SEL__c = 'Email';
                c.Status            = 'New';
                // Asignar cola en función del buzón de entrada del caso
                Id queueId;
                if (em.ToAddress != null) {
                    String toAddr = em.ToAddress.toLowerCase();
                    if (toAddr.contains('info')) {
                        queueId = mailboxToQueueMap.get('support_emailcase');
                        c.CasePriority_SEL__c = 'Medium';
                    } else if (toAddr.contains('privacidad')) {
                        queueId = mailboxToQueueMap.get('privacy_emailcase');
                        c.CasePriority_SEL__c = 'High';
                        c.CaseType_SEL__c = 'Question or Inquiry';
                        c.CaseReason_SEL__c = 'Question about the security of my data';
                    } else {
                        queueId = mailboxToQueueMap.get('support_emailcase');
                        c.CasePriority_SEL__c = 'Medium';
                    }
                }
                c.OwnerId = queueId;
                //c.OwnerId           = mailboxToQueueMap.get('support_emailcase');
                casesToInsert.add(c);
            }

            // Asociar el caso al Customer
            if (acc != null) {
                c.ContactId = acc.PersonContactId;
                c.AccountId = acc.Id;
                System.debug('c.ContactId: ' + c.ContactId);
                System.debug('c.AccountId: ' + c.AccountId);
                // Asociar la deuda al caso si existe solo una
                List<DebtCustomer__c> debts = accountToDebtsMap.get(acc.Id);
                System.debug('debts: ' + debts);
                if (debts != null && debts.size() == 1) {
                    c.Debt_REL__c = debts[0].Debt_REL__c;
                }
            }else if(contactData != null){
                c.ContactId = contactData.Customer_REL__r.PersonContactId;
                c.AccountId = contactData.Customer_REL__c;

                // Asociar la deuda al caso si existe solo una
                List<DebtCustomer__c> debts = accountToDebtsMap.get(contactData.Customer_REL__c);
                System.debug('debts: ' + debts);
                if (debts != null && debts.size() == 1) {
                    c.Debt_REL__c = debts[0].Debt_REL__c;
                }

            }
            c.CaseOrigin_SEL__c = 'Email';
            
            
            // Asignar cola en función del buzón de entrada del caso y Prioridad
            Id queueId;
            if (em.ToAddress != null) {
                String toAddr = em.ToAddress.toLowerCase();
                if (toAddr.contains('info')) {
                    queueId = mailboxToQueueMap.get('support_emailcase');
                    c.CasePriority_SEL__c = 'Medium';
                } else if (toAddr.contains('privacidad')) {
                    queueId = mailboxToQueueMap.get('privacy_emailcase');
                    c.CasePriority_SEL__c = 'High';
                    c.CaseType_SEL__c = 'Question or Inquiry';
                    c.CaseReason_SEL__c = 'Question about the security of my data';
                } else {
                    queueId = mailboxToQueueMap.get('support_emailcase'); 
                    c.CasePriority_SEL__c = 'Medium';
                }
            }
            c.OwnerId = queueId;
            //c.OwnerId = mailboxToQueueMap.get('support_emailcase');
            System.debug('em.RelatedToId: ' + em.RelatedToId);
            if (em.RelatedToId != null) casesToUpdate.add(c);
        }

        // 7. Ejecutar DML
        if (!casesToInsert.isEmpty()) {
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = false;

            try {
                Database.insert(casesToInsert, dmlOpts);
            } catch (DmlException e) {
                System.debug('Error al insertar Caso de Email-To-Case: ' + e.getMessage());
            }
        }
        if (!casesToUpdate.isEmpty()) {
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = false;

            try {
                System.debug('casesToUpdate: ' + casesToUpdate);
                Database.update(casesToUpdate, dmlOpts);
            } catch (DmlException e) {
                System.debug('Error al actualizar Caso de Email-To-Case: ' + e.getMessage());
            }
        }
    }
}