/**
 * @description       : EmailToCaseManagerTest Class
 * @author            : Horizon CX
 * @last modified on  : 09/09/2025
 * @last modified by  : Horizon CX
**/
@isTest
private class EmailToCaseManagerTest {

    @IsTest
    static void testProcessEmail_NewCaseFromAccount() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;

        Debt__c debt1 = TestFactory.createSingleDebt(portfolio, 1000);
        Account debtor1 = TestFactory.createSingleCustomers();
        debtor1.PersonEmail = 'customer@test.com';
        update debtor1;
        DebtCustomer__c dc1 = TestFactory.createSingleDebtCustomerRelation(debt1, debtor1);
        
        
        EmailMessage em = new EmailMessage(
            FromAddress = debtor1.PersonEmail,
            ToAddress   = 'support_emailcase@test.com',
            Subject     = 'Test Subject',
            TextBody    = 'Test Body',
            Incoming    = true
        );

        Test.startTest();
        EmailToCaseManager.processEmails(new List<EmailMessage>{ em });
        Test.stopTest();

        // Assert: se ha creado un Case
        Case createdCase = [SELECT Id, Subject, Description, Origin, Status, AccountId, Debt_REL__c
                            FROM Case
                            WHERE AccountId = :debtor1.Id
                            LIMIT 1];
        System.assertEquals('Test Subject', createdCase.Subject);
        System.assertEquals(debtor1.Id, createdCase.AccountId);
        System.assertNotEquals(null, createdCase.Debt_REL__c, 'Debe vincular deuda si solo hay una');
    }

    @IsTest
    static void testProcessEmail_NewCaseFromContactData() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt2 = TestFactory.createSingleDebt(portfolio, 1000);
        Account debtor2 = TestFactory.createSingleCustomers();
        DebtCustomer__c dc2 = TestFactory.createSingleDebtCustomerRelation(debt2, debtor2);
        ContactData__c cData = TestFactory.createSingleContactData(debt2, debtor2, 'Email', 'cdata@test.com', true, true, 90);
        ContactData__c cData2 = TestFactory.createSingleContactData(debt2, debtor2, 'Email', 'cdata2@test.com', true, true, 10);

        EmailMessage em = new EmailMessage(
            FromAddress = cData2.ContactDataValue__c,
            ToAddress   = 'support_emailcase@test.com',
            Subject     = null,
            TextBody    = null,
            Incoming    = true
        );

        Test.startTest();
        EmailToCaseManager.processEmails(new List<EmailMessage>{ em });
        Test.stopTest();

        // Assert: se ha creado un Case para el Customer del ContactData
        Case createdCase = [SELECT Id, AccountId, Subject, Description
                            FROM Case
                            WHERE AccountId = :cData2.Customer_REL__c
                            LIMIT 1];
        System.assertNotEquals(null, createdCase, 'Debe haberse creado un caso');
        System.assert(createdCase.Subject.startsWith('Caso creado por Email'), 'El subject debe asignarse por defecto');
    }


    @IsTest
    static void testProcessEmail_NotIncoming() {
        // Arrange: Incoming = false → no debería crear nada
        EmailMessage em = new EmailMessage(
            FromAddress = 'irrelevant@test.com',
            ToAddress   = 'support_emailcase@test.com',
            Subject     = 'Should not create',
            Incoming    = false
        );

        Test.startTest();
        EmailToCaseManager.processEmails(new List<EmailMessage>{ em });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Subject = 'Should not create']);
    }
}