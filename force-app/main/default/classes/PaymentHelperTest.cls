/**
 * @description       : PaymentHelperTest Class
 * @author            : Horizon CX
 * @last modified on  : 07/08/2025
 * @last modified by  : Horizon CX
**/
@isTest
private class PaymentHelperTest {

    @isTest
    static void test_updatePromise_PaidAmount_AfterInsert() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 1000);
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 1000, 200, 5, false, 'Predefined');
        List<PromisesInstallment__c> promiseInstallments = [SELECT Id, PaidAmount__c, Promise_REL__c  FROM PromisesInstallment__c WHERE Promise_REL__c =: promise.Id];
        PromisesInstallment__c installment1 = promiseInstallments[0];
        
        Test.startTest();
        Payment__c pay = TestFactory.createSinglePaymentWithPromise(debt, promise, installment1, 200);
        Test.stopTest();

        Promise__c promiseUpdate = [SELECT Id, PaidAmount__c
                                    FROM Promise__c WHERE Id = :promise.Id];
        PromisesInstallment__c installmentUpdate = [SELECT Id, PaidAmount__c
                                                FROM PromisesInstallment__c WHERE Id = :installment1.Id];

        System.assertNotEquals(null,promiseUpdate.PaidAmount__c,'Debería haberse actualizado el Paid Amount en Promise');
        System.assertNotEquals(null,installmentUpdate.PaidAmount__c,'Debería haberse actualizado el Paid Amount en Promise Installment');
    }

    @isTest
    static void test_updatePromise_PaidAmount_afterUpdate() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 1000);

        Payment__c pay = TestFactory.createSinglePayment(debt, 200);

        Promise__c promise = TestFactory.createSinglePromise(debt, true, 1000, 200, 5, false, 'Predefined');
        List<PromisesInstallment__c> promiseInstallments = [SELECT Id, PaidAmount__c, Promise_REL__c  FROM PromisesInstallment__c WHERE Promise_REL__c =: promise.Id];
        PromisesInstallment__c installment1 = promiseInstallments[0];
        
        Payment__c payToUpdate = [SELECT Id, Promise_REL__c, PromisesInstallment_REL__c FROM Payment__c WHERE Id =: pay.Id];

        Test.startTest();
        payToUpdate.Promise_REL__c = promise.Id;
        payToUpdate.PromisesInstallment_REL__c = installment1.Id;
        update payToUpdate;
        Test.stopTest();

        Promise__c promiseUpdate = [SELECT Id, PaidAmount__c
                                    FROM Promise__c WHERE Id = :promise.Id];
        PromisesInstallment__c installmentUpdate = [SELECT Id, PaidAmount__c
                                                FROM PromisesInstallment__c WHERE Id = :installment1.Id];

        System.assertNotEquals(null,promiseUpdate.PaidAmount__c,'Debería haberse actualizado el Paid Amount en Promise');
        System.assertNotEquals(null,installmentUpdate.PaidAmount__c,'Debería haberse actualizado el Paid Amount en Promise Installment');
    }

    @isTest
    static void test_updatePromise_PaidAmount_Returned() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 1000);

        Payment__c pay = TestFactory.createSinglePaymentReturned(debt, 200);

        Promise__c promise = TestFactory.createSinglePromise(debt, true, 1000, 200, 5, false, 'Predefined');
        List<PromisesInstallment__c> promiseInstallments = [SELECT Id, PaidAmount__c, Promise_REL__c  FROM PromisesInstallment__c WHERE Promise_REL__c =: promise.Id];
        PromisesInstallment__c installment1 = promiseInstallments[0];
        
        Payment__c payToUpdate = [SELECT Id, Promise_REL__c, PromisesInstallment_REL__c FROM Payment__c WHERE Id =: pay.Id];

        Test.startTest();
        payToUpdate.Promise_REL__c = promise.Id;
        payToUpdate.PromisesInstallment_REL__c = installment1.Id;
        update payToUpdate;
        Test.stopTest();

        Promise__c promiseUpdate = [SELECT Id, PaidAmount__c
                                    FROM Promise__c WHERE Id = :promise.Id];
        PromisesInstallment__c installmentUpdate = [SELECT Id, PaidAmount__c
                                                FROM PromisesInstallment__c WHERE Id = :installment1.Id];

        System.assertNotEquals(null,promiseUpdate.PaidAmount__c,'Debería haberse actualizado el Paid Amount en Promise');
        System.assertNotEquals(null,installmentUpdate.PaidAmount__c,'Debería haberse actualizado el Paid Amount en Promise Installment');
    }

    @isTest
    static void testAux() {
        Automation_Settings__c setting = TestFactory.customSetting();
        
        PaymentHandler handler = new PaymentHandler(0);
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