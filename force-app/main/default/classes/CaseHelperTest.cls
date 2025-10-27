/**
 * @description       : CaseHelperTest Class
 * @author            : Horizon CX
 * @last modified on  : 03/09/2025
 * @last modified by  : Horizon CX
**/
@isTest
private class CaseHelperTest {
    @isTest
    static void test_updateCase_DebtField() {

        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 1000);

        Account customer = TestFactory.createSingleCustomers();
        DebtCustomer__c debtCustoomer = TestFactory.createSingleDebtCustomerRelation(debt, customer);
        
        Test.startTest();
        Case caso = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        insert caso;
        Test.stopTest();

        Case casoFromDb = [SELECT Id, Debt_REL__c FROM Case WHERE Id = :caso.Id];
        System.assertNotEquals(null,casoFromDb.Debt_REL__c,'Se debería haber actualizado el campo Debt en caso');
    }
    
    @isTest
    static void test_assignPriorityByReason_AllScenarios() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account customer = TestFactory.createSingleCustomers();

        List<Case> testCases = new List<Case>();
        
        // Problema → Alta
        Case caso = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso.CaseOrigin_SEL__c = 'Customer Portal - Cases';
        caso.CaseType_SEL__c = 'Problem';
        caso.CaseReason_SEL__c = 'I can not make a payment';
        testCases.add(caso);
        
        Case caso1 = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso1.CaseOrigin_SEL__c = 'Customer Portal - Cases';
        caso1.CaseType_SEL__c = 'Problem';
        caso1.CaseReason_SEL__c = 'I encountered a system error';
        testCases.add(caso1);

        Case caso2 = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso2.CaseOrigin_SEL__c = 'Customer Portal - Cases';
        caso2.CaseType_SEL__c = 'Problem';
        caso2.CaseReason_SEL__c = 'I have not received payment confirmation';
        testCases.add(caso2);

        // Question or Inquiry → Media
        Case caso3 = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso3.CaseOrigin_SEL__c = 'Customer Portal - Cases';
        caso3.CaseType_SEL__c = 'Question or Inquiry';
        caso3.CaseReason_SEL__c = 'I want to better understand my debt';
        testCases.add(caso3);

        Case caso4 = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso4.CaseOrigin_SEL__c = 'Customer Portal - Cases';
        caso4.CaseType_SEL__c = 'Question or Inquiry';
        caso4.CaseReason_SEL__c = 'I do not understand the date or amount of a charge';
        testCases.add(caso4);

        // Complaint → Media o Baja
        Case caso5 = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso5.CaseOrigin_SEL__c = 'Customer Portal - Cases';
        caso5.CaseType_SEL__c = 'Complaint';
        caso5.CaseReason_SEL__c = 'I disagree with a charge';
        testCases.add(caso5);

        Case caso6 = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso6.CaseOrigin_SEL__c = 'Customer Portal - Cases';
        caso6.CaseType_SEL__c = 'Complaint';
        caso6.CaseReason_SEL__c = 'I am not satisfied with the service received';
        testCases.add(caso6);

        // My Payments or Payment Plan → Baja, Alta, Media
        Case caso7 = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso7.CaseOrigin_SEL__c = 'Customer Portal - Cases';
        caso7.CaseType_SEL__c = 'My Payments or Payment Plan';
        caso7.CaseReason_SEL__c = 'Set up a payment plan';
        testCases.add(caso7);

        Case caso8 = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso8.CaseOrigin_SEL__c = 'Customer Portal - Cases';
        caso8.CaseType_SEL__c = 'My Payments or Payment Plan';
        caso8.CaseReason_SEL__c = 'Change my current plan';
        testCases.add(caso8);

        Case caso9 = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso9.CaseOrigin_SEL__c = 'Customer Portal - Cases';
        caso9.CaseType_SEL__c = 'My Payments or Payment Plan';
        caso9.CaseReason_SEL__c = 'Cancel my plan';
        testCases.add(caso9);

        // Other → Baja
        Case caso10 = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso10.CaseOrigin_SEL__c = 'Customer Portal - Cases';
        caso10.CaseType_SEL__c = 'Other Reason';
        caso10.CaseReason_SEL__c = 'Other general reason';
        testCases.add(caso10);

        Test.startTest();
        CaseHelper.assignPriorityByReason(testCases);
        Test.stopTest();

        // Assertions
        System.assertEquals('High',  testCases[0].CasePriority_SEL__c);
        System.assertEquals('High',  testCases[1].CasePriority_SEL__c);
        System.assertEquals('High',  testCases[2].CasePriority_SEL__c);

        System.assertEquals('Medium', testCases[3].CasePriority_SEL__c);
        System.assertEquals('Medium', testCases[4].CasePriority_SEL__c);

        System.assertEquals('Medium', testCases[5].CasePriority_SEL__c);
        System.assertEquals('Low',  testCases[6].CasePriority_SEL__c);

        System.assertEquals('Low',  testCases[7].CasePriority_SEL__c);
        System.assertEquals('High',  testCases[8].CasePriority_SEL__c);
        System.assertEquals('Medium', testCases[9].CasePriority_SEL__c);

        System.assertEquals('Low',  testCases[10].CasePriority_SEL__c);
    }

    @isTest
    static void test_assignPriorityByReason_NotFromPortal() {
        Automation_Settings__c setting = TestFactory.customSetting();

        // Caso que no viene del portal → no debe asignar prioridad
        Account customer = TestFactory.createSingleCustomers();
        
        // Problema → Alta
        Case caso = TestFactory.createSingleCaseByOrigen(customer, 'Email');
        insert caso;

        Test.startTest();
        CaseHelper.assignPriorityByReason(new List<Case>{ caso });
        Test.stopTest();

        System.assertEquals(null, caso.CasePriority_SEL__c, 'No debería asignar prioridad si no es del portal');
    }

    @IsTest
    static void testCreateContactData_NewEmailAndPhone() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account customer = TestFactory.createSingleCustomers();

        Test.startTest();
        Case caso = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso.ContactEmail_EML__c = 'new@email.com';
        caso.ContactPhone_PHN__c = '617654321';
        insert caso;
        Test.stopTest();

        // Verificar que se crearon los ContactData
        List<ContactData__c> cds = [SELECT ContactDataType_SEL__c, ContactDataValue__c
                                    FROM ContactData__c
                                    WHERE Customer_REL__c = :customer.Id
                                    AND ContactDataValue__c IN ('new@email.com','617654321')];
        System.assertEquals(2, cds.size(), 'Deben haberse creado ambos ContactData');
    }

    @IsTest
    static void testCreateContactData_ExistingEmailAndPhone() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account customer = TestFactory.createSingleCustomers();

        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 1000);
        DebtCustomer__c debtCustoomer = TestFactory.createSingleDebtCustomerRelation(debt, customer);
        ContactData__c cd1 = TestFactory.createSingleContactData(debt,customer,'Email','new@email.com', true, true, 90);
        ContactData__c cd2 = TestFactory.createSingleContactData(debt,customer,'Phone','617654321', true, true, 90);

        Test.startTest();
        Case caso = TestFactory.createSingleCaseByOrigen(customer, 'Customer Portal - Cases');
        caso.ContactEmail_EML__c = 'new@email.com';
        caso.ContactPhone_PHN__c = '617654321';
        insert caso;
        Test.stopTest();

        // Verificar que no se creó ningún registro duplicado
        Integer countCD = [SELECT COUNT() FROM ContactData__c WHERE Customer_REL__c = :customer.Id];
        System.assertEquals(2, countCD, 'No deben haberse creado registros duplicados');
    }

    @isTest
    static void testAux() {
        Automation_Settings__c setting = TestFactory.customSetting();
        
        CaseHandler handler = new CaseHandler(0);
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
        handler.afterUpdate(
            new List<SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
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