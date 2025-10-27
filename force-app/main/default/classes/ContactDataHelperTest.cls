/**
 * @description       : ContactDataHelperTest Class
 * @author            : Horizon CX
 * @last modified on  : 21/08/2025
 * @last modified by  : Horizon CX
 *      - 14/10/2025  : Modificado para cubrir el método updateActiveOKforCommCD
**/
@isTest
public with sharing class ContactDataHelperTest {
    @isTest
    static void test_afterInsert_UpdatePA() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 1000);
        Account debtor = TestFactory.createSingleCustomers();
        DebtCustomer__c debtCustomer = TestFactory.createSingleDebtCustomerRelation(debt, debtor);
        
        Test.startTest();
        ContactData__c concData1 = TestFactory.createSingleContactData(debt, debtor, 'Email', 'test@test.com', true, true, 80);
        ContactData__c concData2 = TestFactory.createSingleContactData(debt, debtor, 'Phone', '926231765', true, true, 80);
        ContactData__c concData3 = TestFactory.createSingleContactData(debt, debtor, 'MobilePhone', '610000000', true, true, 60);
        Test.stopTest();

        Account debtorUpdated = [SELECT Id, Phone, PersonEmail FROM Account WHERE Id =: debtor.Id];

        System.assertEquals(debtorUpdated.Phone,'926231765','El teléfono se debería haber rellenado');
        System.assertEquals(debtorUpdated.PersonEmail,'test@test.com','El email se debería haber rellenado');
    }

    @isTest
    static void test_afterUpdate_UpdatePA() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 1000);
        Account debtor = TestFactory.createSingleCustomers();
        DebtCustomer__c debtCustomer = TestFactory.createSingleDebtCustomerRelation(debt, debtor);
    
        ContactData__c concData1 = TestFactory.createSingleContactData(debt, debtor, 'Email', 'test@test.com', true, true, 80);
        ContactData__c concData2 = TestFactory.createSingleContactData(debt, debtor, 'Phone', '926231765', false, true, 80);
        ContactData__c concData3 = TestFactory.createSingleContactData(debt, debtor, 'MobilePhone', '610000000', true, true, 60);
        ContactData__c concData4 = TestFactory.createSingleContactData(debt, debtor, 'Email', 'prueba@test.com', true, true, 100);
        
        Test.startTest();
        concData2.IsValid__c = true;
        update concData2;
        concData4.PriorityScore_NUM__c = 20;
        update concData4;
        Test.stopTest();

        Account debtorUpdated = [SELECT Id, Phone, PersonEmail FROM Account WHERE Id =: debtor.Id];

        System.assertEquals(debtorUpdated.Phone,'926231765','El teléfono se debería haber rellenado');
        System.assertEquals(debtorUpdated.PersonEmail,'test@test.com','El email se debería haber rellenado');
    }

    @IsTest
    static void testUpdateActiveOKforCommCD() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 1000);
        Account debtor = TestFactory.createSingleCustomers();
        DebtCustomer__c debtCustomer = TestFactory.createSingleDebtCustomerRelation(debt, debtor);

        ContactData__c concData1 = TestFactory.createSingleContactData(debt, debtor, 'Email', 'test@test.com', true, true, 80);
        concData1.OK_Communications_BOL__c = TRUE;
        update concData1;
        ContactData__c concData2 = TestFactory.createSingleContactData(debt, debtor, 'Phone', '926231765', true, true, 80);
        concData2.OK_Communications_BOL__c = TRUE;
        update concData2;
        ContactData__c concData3 = TestFactory.createSingleContactData(debt, debtor, 'MobilePhone', '610000000', true, true, 60);
        ContactData__c concData4 = TestFactory.createSingleContactData(debt, debtor, 'Email', 'prueba@test.com', true, true, 100);

        Test.startTest();
        concData3.OK_Communications_BOL__c = TRUE;
        update concData3;
        concData4.OK_Communications_BOL__c = TRUE;
        update concData4;
        Test.stopTest();

        List<ContactData__c> cds = [SELECT Id, Name, ContactDataType_SEL__c, ContactDataValue__c, OK_Communications_BOL__c FROM ContactData__c WHERE Id IN :new List<Id>{concData1.Id, concData2.Id, concData3.Id, concData4.Id}];

        Map<String, ContactData__c> cdMap = new Map<String, ContactData__c>();
        for(ContactData__c cd : cds){
            cdMap.put(cd.ContactDataValue__c, cd);
        }

        System.assert(cdMap.get('test@test.com').OK_Communications_BOL__c == FALSE, 'concData1 debe ser FALSE');
        System.assert(cdMap.get('prueba@test.com').OK_Communications_BOL__c == TRUE, 'concData4 debe pasar a TRUE');
        System.assert(cdMap.get('926231765').OK_Communications_BOL__c == FALSE, 'concData2 debe ser FALSE');
        System.assert(cdMap.get('610000000').OK_Communications_BOL__c == TRUE, 'concData3 debe ser TRUE');
    }

    @isTest
    static void testAux() {
        Automation_Settings__c setting = TestFactory.customSetting();
        
        ContactDataHandler handler = new ContactDataHandler(0);
        handler.beforeInsert(
            new List<SObject>()
        );
        handler.beforeUpdate(
            new List<SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
            new Map<Id, SObject>()
        );
        handler.beforeDelete(
            new List<SObject>(),
            new Map<Id, SObject>()
        );
        handler.afterDelete(
            new List<SObject>(),
            new Map<Id, SObject>()
        );
        handler.afterUndelete(
            new List<SObject>(),
            new Map<Id, SObject>()
        );
    }
}