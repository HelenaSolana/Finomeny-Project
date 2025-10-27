/**
 * @description       : PromiseInstallmentHelperTest Class
 * @author            : Horizon CX
 * @last modified on  : 12/08/2025
 * @last modified by  : Horizon CX
**/
@isTest
private class PromiseInstallmentHelperTest {

    @isTest
    static void test_updatePromise_Status_PreBroken() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 9800, 490, 20, false, 'Predefined');
        
        List<PromisesInstallment__c> installments = [SELECT Id, Status_FOR__c, Promise_REL__c, PaymentDate__c, IsActive_BOL__c  FROM PromisesInstallment__c WHERE Promise_REL__c =: promise.Id];
        PromisesInstallment__c installmentToUpdate = installments[0];

        Test.startTest();
        installmentToUpdate.PaymentDate__c = Date.today() - 15;
        update installmentToUpdate;
        Test.stopTest();

        Promise__c promiseUpdated = [SELECT Id, StatusPotential_SEL__c FROM Promise__c WHERE Id =: installmentToUpdate.Promise_REL__c];

        System.assertEquals('Pre-Broken',promiseUpdated.StatusPotential_SEL__c,'Debería haberse actualizado el Status de la Promise');
    }

    @isTest
    static void test_updatePromise_Status_Pending() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 9800, 490, 20, false, 'Predefined');
        
        List<PromisesInstallment__c> installments = [SELECT Id, Promise_REL__c, PaymentDate__c, InstallmentsAmount__c  FROM PromisesInstallment__c WHERE Promise_REL__c =: promise.Id];
        PromisesInstallment__c installmentToUpdate = installments[0];
        installmentToUpdate.PaymentDate__c = Date.today() - 15;
        update installmentToUpdate;

        Test.startTest();
        Payment__c payment = TestFactory.createSinglePaymentWithPromise(debt, promise, installmentToUpdate, installmentToUpdate.InstallmentsAmount__c);
        Test.stopTest();

        Promise__c promiseUpdated = [SELECT Id, StatusPotential_SEL__c FROM Promise__c WHERE Id =: installmentToUpdate.Promise_REL__c];

        System.assertEquals('Pending',promiseUpdated.StatusPotential_SEL__c,'Debería haberse actualizado el Status de la Promise');
    }

    @isTest
    static void test_updatePromise_Status_Broken() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 9800, 490, 20, false, 'Predefined');
        
        List<PromisesInstallment__c> installments = [SELECT Id, Promise_REL__c, PaymentDate__c  FROM PromisesInstallment__c WHERE Promise_REL__c =: promise.Id];
        PromisesInstallment__c installmentToUpdate = installments[0];
        installmentToUpdate.PaymentDate__c = Date.today() - 15;
        update installmentToUpdate; 
        
        Test.startTest();
        installmentToUpdate.PaymentDate__c = (Date.today()).addMonths(-2);
        update installmentToUpdate;
        Test.stopTest();

        Promise__c promiseUpdated = [SELECT Id, StatusPotential_SEL__c FROM Promise__c WHERE Id =: installmentToUpdate.Promise_REL__c];

        System.assertEquals('Broken',promiseUpdated.StatusPotential_SEL__c,'Debería haberse actualizado el Status de la Promise');
    }

    @isTest
    static void test_updatePromise_NextPaymentDay() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 9800, 490, 20, false, 'Predefined');
        
        List<PromisesInstallment__c> installments = [SELECT Id, Promise_REL__c, PaymentDate__c  FROM PromisesInstallment__c WHERE Promise_REL__c =: promise.Id];
        PromisesInstallment__c installmentToUpdate = installments[0];
        Test.startTest();
        installmentToUpdate.PaidAmount__c = 490;
        update installmentToUpdate;
        Test.stopTest();

        Promise__c promiseUpdated = [SELECT Id, PotentialNextPaymentdate__c FROM Promise__c WHERE Id =: installmentToUpdate.Promise_REL__c];

        System.assertNotEquals(null,promiseUpdated.PotentialNextPaymentdate__c,'Debería haberse actualizado el PotentialNextPaymentdate__c de la Promise');
    }

    @isTest
    static void testAux() {
        Automation_Settings__c setting = TestFactory.customSetting();
        
        PromiseInstallmentHandler handler = new PromiseInstallmentHandler(0);
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
        handler.afterInsert(
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