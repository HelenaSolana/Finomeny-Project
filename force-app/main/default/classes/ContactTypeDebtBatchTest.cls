/**
 * @description       : ContactTypeDebtBatchTest Class
 * @author            : Horizon CX
 * @last modified on  : 07/08/2025
 * @last modified by  : Horizon CX
**/
@isTest
private class ContactTypeDebtBatchTest {

    @isTest
    static void testContactData_OnlyEmail() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Account customer = TestFactory.createSingleCustomers();
        DebtCustomer__c debtCustoomer = TestFactory.createSingleDebtCustomerRelation(debt, customer);

        ContactData__c contactDataEmail = TestFactory.createSingleContactData(debt, customer, 'Email', 'test@test.com',true, true, 80);
        ContactData__c contactDataPhone = TestFactory.createSingleContactData(debt, customer, 'MoiblePhone', '926544243', true, false, 76);
        
        Test.startTest();
        ContactTypeDebtBatch batch = new ContactTypeDebtBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Debt__c debtUpdate = [SELECT Id, ContactType__c FROM Debt__c WHERE Id = :debt.Id];
        System.assertEquals('Only Email',debtUpdate.ContactType__c,'Debería haberse actualizado el campo Contact Type de la Debt');
    }

    @isTest
    static void testContactData_OnlyPhone() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Account customer = TestFactory.createSingleCustomers();
        DebtCustomer__c debtCustoomer = TestFactory.createSingleDebtCustomerRelation(debt, customer);

        ContactData__c contactDataEmail = TestFactory.createSingleContactData(debt, customer, 'Email', 'test@test.com', true, false, 90);
        ContactData__c contactDataPhone = TestFactory.createSingleContactData(debt, customer, 'Phone', '926544243', true, true, 100);
        
        Test.startTest();
        ContactTypeDebtBatch batch = new ContactTypeDebtBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Debt__c debtUpdate = [SELECT Id, ContactType__c FROM Debt__c WHERE Id = :debt.Id];
        System.assertEquals('Only Phone',debtUpdate.ContactType__c,'Debería haberse actualizado el campo Contact Type de la Debt');
    }

    @isTest
    static void testContactData_MobileAndEmail() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Account customer = TestFactory.createSingleCustomers();
        DebtCustomer__c debtCustoomer = TestFactory.createSingleDebtCustomerRelation(debt, customer);

        ContactData__c contactDataEmail = TestFactory.createSingleContactData(debt, customer, 'Email', 'test@test.com', true, true, 45);
        ContactData__c contactDataPhone = TestFactory.createSingleContactData(debt, customer, 'MobilePhone', '926544243', true, true, 90);
        
        Test.startTest();
        ContactTypeDebtBatch batch = new ContactTypeDebtBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Debt__c debtUpdate = [SELECT Id, ContactType__c FROM Debt__c WHERE Id = :debt.Id];
        System.assertEquals('Phone + Email',debtUpdate.ContactType__c,'Debería haberse actualizado el campo Contact Type de la Debt');
    }

    @isTest
    static void testContactData_Other() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Account customer = TestFactory.createSingleCustomers();
        DebtCustomer__c debtCustoomer = TestFactory.createSingleDebtCustomerRelation(debt, customer);

        ContactData__c contactDataEmail = TestFactory.createSingleContactData(debt, customer, 'Address', 'Calle', true, true, 34);
        ContactData__c contactDataPhone = TestFactory.createSingleContactData(debt, customer, 'MobilePhone','926734567', true, false, 78);
        
        Test.startTest();
        ContactTypeDebtBatch batch = new ContactTypeDebtBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Debt__c debtUpdate = [SELECT Id, ContactType__c FROM Debt__c WHERE Id = :debt.Id];
        System.assertEquals('No Contact Data',debtUpdate.ContactType__c,'Debería haberse actualizado el campo Contact Type de la Debt');
    }

    @isTest
    static void test_scheduleDailyAt6AM_withCustomJobName() {
        Test.startTest();
        String jobName = 'Test_ContactTypeDebtBatchSchedule_' + System.currentTimeMillis();
        ContactTypeDebtBatchSchedule.scheduleDailyAt6AM(jobName);
        Test.stopTest();

        // Verificamos que el job ha sido programado correctamente
        List<CronTrigger> jobs = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
        ];
        
        System.assertEquals(1, jobs.size(), 'Debe existir exactamente un job con el nombre programado.');
        System.assertEquals('0 0 6 * * ?', jobs[0].CronExpression, 'La expresión CRON debería ser a las 6:00 a.m. todos los días.');
    }
}