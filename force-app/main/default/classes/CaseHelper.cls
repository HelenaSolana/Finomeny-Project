/**
 * @description       : CaseHelper Class
 * @author            : Horizon CX
 * @last modified on  : 03/09/2025
 * @last modified by  : Horizon CX
**/
public with sharing class CaseHelper {

    /**
     * @description Método que actualiza el campo Prioridad cuando el caso es nuevo creado desde el formulario del portal
     * @param List<Case> newRecordList
     * @return void
     */
    public static void assignPriorityByReason(List<Case> newRecordList) {
        if (newRecordList == null || newRecordList.isEmpty()) return;
    
        for (Case cs : newRecordList) {
            if (cs.CaseOrigin_SEL__c != 'Customer Portal - Cases' && cs.CaseType_SEL__c != null && cs.CaseReason_SEL__c != null) {
                continue;
            }
    
            String priority;
    
            switch on cs.CaseType_SEL__c {
                when 'Problem' {
                    switch on cs.CaseReason_SEL__c {
                        when 'I can not make a payment', 'I encountered a system error', 'I have not received payment confirmation' {
                            priority = 'High';
                        }
                        when else { priority = null; }
                    }
                }
                when 'Question or Inquiry' {
                    switch on cs.CaseReason_SEL__c {
                        when 'I want to better understand my debt', 'I do not understand the date or amount of a charge' {
                            priority = 'Medium';
                        }
                        when else { priority = null; }
                    }
                }
                when 'Complaint' {
                    switch on cs.CaseReason_SEL__c {
                        when 'I disagree with a charge' { priority = 'Medium'; }
                        when 'I am not satisfied with the service received' { priority = 'Low'; }
                        when else { priority = null; }
                    }
                }
                when 'My Payments or Payment Plan' {
                    switch on cs.CaseReason_SEL__c {
                        when 'Set up a payment plan' { priority = 'Low'; }
                        when 'Change my current plan' { priority = 'High'; }
                        when 'Cancel my plan' { priority = 'Medium'; }
                        when else { priority = null; }
                    }
                }
                when 'Other Reason' {
                    switch on cs.CaseReason_SEL__c {
                        when 'Other general reason' { priority = 'Low'; }
                        when else { priority = null; }
                    }
                }
                when else { priority = null; }
            }
    
            if (priority != null) {
                cs.Priority = priority;
                cs.CasePriority_SEL__c = priority;
            }
        }
    }

    /**
     * @description Método que actualiza el caso nuevo creado desde el formulario del portal
     * @param List<Case> newRecordList
     * @return void
     */
    public static void updateCase_DebtField(List<Case> newRecordList) {
        if (newRecordList == null || newRecordList.isEmpty()) return;

        List<Case> caseList =  new List<Case>();
        List<Case> caseToUpdate =  new List<Case>();
        Set<Id> customerIds = new Set<Id>();
        Map<Id, List<DebtCustomer__c>> customerToDebtsMap = new Map<Id, List<DebtCustomer__c>>();

        for (Case caso : newRecordList) {
            if((caso.CaseOrigin_SEL__c == 'Customer Portal - Cases' || caso.Origin == 'Customer Portal - Cases')
                && caso.Debt_REL__c == null 
                && caso.AccountId != null){
                caseList.add(caso);
                customerIds.add(caso.AccountId);
            } 
        }

        if(!caseList.isEmpty()){
            if (!customerIds.isEmpty()) {
                for (DebtCustomer__c dc : [
                    SELECT Id, Debt_REL__c, Customer_REL__c, Debt_REL__r.Status_SEL__c
                    FROM DebtCustomer__c
                    WHERE Customer_REL__c IN : customerIds 
                    AND Debt_REL__r.Status_SEL__c = 'Open'
                ]) {
                    if (!customerToDebtsMap.containsKey(dc.Customer_REL__c)) {
                        customerToDebtsMap.put(dc.Customer_REL__c, new List<DebtCustomer__c>());
                    }
                    customerToDebtsMap.get(dc.Customer_REL__c).add(dc);
                }
            }
        }

        for (Case caso : caseList) {
            List<DebtCustomer__c> debts = customerToDebtsMap.get(caso.AccountId);
            if (debts != null && debts.size() == 1) {
                caseToUpdate.add(new Case(
                    Id = caso.Id, 
                    Debt_REL__c = debts[0].Debt_REL__c
                ));
            }
        }

        if (!caseToUpdate.isEmpty()) {
            try {
                update caseToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar la deuda en el Caso: ' + e.getMessage());
            }
        }
    }

    /**
    * @description Método que fuerza la ejecución de las reglas de asignación
    *              para los casos creados desde el Portal
    * @param List<Case> newRecordList
    * @return void
    */
    public static void applyAssignmentRulesForPortalCases(List<Case> newRecordList) {
        if (newRecordList == null || newRecordList.isEmpty()) return;

        List<Case> portalCases = new List<Case>();

        for (Case c : newRecordList) {
            if (c.CaseOrigin_SEL__c == 'Customer Portal - Cases') {
                portalCases.add(
                new Case(
                    Id = c.Id
                )
            );
            }
        }

        if (!portalCases.isEmpty()) {
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = true; // fuerza assignment rules

            try {
                Database.update(portalCases, dmlOpts);
            } catch (DmlException e) {
                System.debug('Error al aplicar Assignment Rules en Casos del portal: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Método que despues de la creación del caso nuevo desde el formulario del portal evalua si el Customer
     *              tiene como ContactData relacionados los datos introducidos en Contact Email y Contact Phone
     *              si no los encuentra los crea
     * @param List<Case> newRecordList
     * @return void
     */
    public static void createContactData(List<Case> newRecordList) {
        if (newRecordList == null || newRecordList.isEmpty()) return;

        List<Case> caseList =  new List<Case>();
        Set<Id> customerIds = new Set<Id>();
        Map<Id, List<ContactData__c>> customerToCDatasMap = new Map<Id, List<ContactData__c>>();
        //Map<String, String> contactDataValuesMap = new Map<String, String>();
        List<ContactData__c> cDataToInsert =  new List<ContactData__c>();


        for (Case caso : newRecordList) {
            if((caso.CaseOrigin_SEL__c == 'Customer Portal - Cases' || caso.Origin == 'Customer Portal - Cases')
                && caso.AccountId != null){
                caseList.add(caso);
                customerIds.add(caso.AccountId);
            } 
        }

        if (!customerIds.isEmpty()) {
            for (ContactData__c cd : [
                SELECT Id, Customer_REL__c, ContactDataType_SEL__c, ContactDataValue__c
                FROM ContactData__c
                WHERE Customer_REL__c IN : customerIds 
                AND ContactDataType_SEL__c IN ('Email', 'Phone', 'MobilePhone')
            ]) {
                if (!customerToCDatasMap.containsKey(cd.Customer_REL__c)) {
                    customerToCDatasMap.put(cd.Customer_REL__c, new List<ContactData__c>());
                }
                customerToCDatasMap.get(cd.Customer_REL__c).add(cd);
            }
        }
        
        for (Case caso : caseList) {
            
            List<ContactData__c> existingCData = customerToCDatasMap.get(caso.AccountId);
            if (existingCData == null) existingCData = new List<ContactData__c>();
            
            // Email
            if (String.isNotBlank(caso.ContactEmail_EML__c)) {
                Boolean existsEmail = false;
                for (ContactData__c cd : existingCData) {
                    if (cd.ContactDataType_SEL__c == 'Email' 
                        && cd.ContactDataValue__c == caso.ContactEmail_EML__c) {
                        existsEmail = true;
                        break;
                    }
                }
                if (!existsEmail) {
                    cDataToInsert.add(new ContactData__c(
                        Customer_REL__c = caso.AccountId,
                        ContactDataType_SEL__c = 'Email',
                        ContactDataValue__c = caso.ContactEmail_EML__c,
                        Source_SEL__c = 'Web Form',
                        OwnerType_SEL__c = 'Debt owner/Titular',
                        IsValid__c = false,
                        IsContactable__c = false,
                        Ispreferred_BOL__c = false,
                        OK_Communications_BOL__c = false
                    ));
                }
            }

            // Phone o MobilePhone
            if (String.isNotBlank(caso.ContactPhone_PHN__c)) {
                Boolean existsPhone = false;
                for (ContactData__c cd : existingCData) {
                    if ((cd.ContactDataType_SEL__c == 'Phone' || cd.ContactDataType_SEL__c == 'MobilePhone') 
                        && cd.ContactDataValue__c == caso.ContactPhone_PHN__c) {
                        existsPhone = true;
                        break;
                    }
                }
                if (!existsPhone) {
                    cDataToInsert.add(new ContactData__c(
                        Customer_REL__c = caso.AccountId,
                        ContactDataType_SEL__c = 'Phone',
                        ContactDataValue__c = caso.ContactPhone_PHN__c,
                        Source_SEL__c = 'Web Form',
                        OwnerType_SEL__c = 'Debt owner/Titular',
                        IsValid__c = false,
                        IsContactable__c = false,
                        Ispreferred_BOL__c = false,
                        OK_Communications_BOL__c = false
                    ));
                }
            }
        }

        if (!cDataToInsert.isEmpty()) {
            try {
                insert cDataToInsert;
            } catch (DmlException e) {
                System.debug('Error al crear Contact Data: ' + e.getMessage());
            }
        }
    }
}