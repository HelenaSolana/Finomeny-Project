/**
 * @description       : PromiseHelperTest Class
 * @author            : Horizon CX
 * @last modified on  : 07/08/2025
 * @last modified by  : Horizon CX
**/
@isTest
private class PromiseHelperTest {

    @isTest
    static void test_updateWriteOffAmount_DebtAndPromise() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 1000);
        
        Test.startTest();
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 8000, 200, 4, false, 'Predefined');
        Test.stopTest();

        Promise__c promiseUpdate = [SELECT Id, WriteOffAmount_CUR__c
                                    FROM Promise__c WHERE Id = :promise.Id];
        Debt__c debtUpdate = [SELECT Id, WriteOffAmount__c
                                    FROM Debt__c WHERE Id = :debt.Id];

        System.assertNotEquals(null,promiseUpdate.WriteOffAmount_CUR__c,'Debería haberse actualizado el WriteOffAmount_CUR__c en Promise');
        System.assertNotEquals(null,debtUpdate.WriteOffAmount__c,'Debería haberse actualizado el WriteOffAmount__c en Debt');
    }

    @isTest
    static void test_createPromisesInstallmentPredefined() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        
        Test.startTest();
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 9800, 490, 20, false, 'Predefined');
        Test.stopTest();

        List<PromisesInstallment__c> promiseInstallments = [SELECT Id, PaidAmount__c, Promise_REL__c  FROM PromisesInstallment__c WHERE Promise_REL__c =: promise.Id];

        System.assertEquals(20,promiseInstallments.size(),'Deberían haberse creado Installments en Promise');
    }

    @isTest
    static void test_createPromisesInstallmentCustom() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        
        Test.startTest();
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 9800, 490, null, false, 'Custom');
        Test.stopTest();

        List<PromisesInstallment__c> promiseInstallments = [SELECT Id, PaidAmount__c, Promise_REL__c  FROM PromisesInstallment__c WHERE Promise_REL__c =: promise.Id];

        System.assertNotEquals(null,promiseInstallments.size(),'Deberían haberse creado Installments en Promise');
    }

    @isTest
    static void test_updateLastPromisesCheck() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 9800, 490, 20, false, 'Predefined');
        
        Test.startTest();
        Promise__c promise2 = TestFactory.createSinglePromise(debt, true, 9500, 475, 20, false, 'Predefined');
        Test.stopTest();

        List<PromisesInstallment__c> installmentsInactive = [SELECT Id, IsActive_BOL__c, Promise_REL__c  FROM PromisesInstallment__c WHERE Promise_REL__c =: promise.Id AND IsActive_BOL__c = false];
        Promise__c promiseUpdated = [SELECT Id, LastPromise_BOL__c FROM Promise__c WHERE Id = :promise.Id];

        System.assertEquals(20,installmentsInactive.size(),'Deberían haberse creado desactivado los Installments en Promise 1');
        System.assertEquals(false,promiseUpdated.LastPromise_BOL__c,'Debería haberse puesto a false el campo LastPromise_BOL__c en Promise 1');
    }

    @isTest
    static void test_updateBrokenDate() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 9800, 490, 20, false, 'Predefined');
        
        Test.startTest();
        promise.StatusPotential_SEL__c = 'Broken';
        update promise;
        Test.stopTest();

        Promise__c promiseUpdated = [SELECT Id, BrokenDate__c FROM Promise__c WHERE Id = :promise.Id];

        System.assertNotEquals(null,promiseUpdated.BrokenDate__c,'Deberían haberse rellenado el campo Broken Date en Promise');
    }

    @isTest
    static void test_updateStatusPromise() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 9800, 490, 20, false, 'Predefined');
        
        Test.startTest();
        promise.PaidAmount__c = 9800;
        update promise;
        Test.stopTest();

        Promise__c promiseUpdated = [SELECT Id,StatusPotential_SEL__c  FROM Promise__c WHERE Id = :promise.Id];

        System.assertEquals('Paid',promiseUpdated.StatusPotential_SEL__c,'Deberían haberse actualizado el campo Status en Promise');
    }

    @isTest
    static void test_updatePromise_InstallmentAmount() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);

        Test.startTest();
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 9800, 0, 10, false, 'Predefined');
        Test.stopTest();

        List<Promise__c> promiseUpdated = [SELECT Id, InstallmentsAmount__c  FROM Promise__c WHERE Id =: promise.Id];

        System.assertEquals(980, promiseUpdated[0].InstallmentsAmount__c, 'Deberían haberse actualizado el Installments Amount en Promise');
    }

    @isTest
    static void test_updatePromiseInstallments() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Promise__c promise = TestFactory.createSinglePromise(debt, true, 9800, 490, 20, false, 'Predefined');

        Test.startTest();
        promise.NumberOfInstallments__c = 10;
        update promise;
        Test.stopTest();

        List<PromisesInstallment__c> promiseInstallments = [SELECT Id, PaidAmount__c, Promise_REL__c  FROM PromisesInstallment__c WHERE Promise_REL__c =: promise.Id];

        System.assertEquals(10,promiseInstallments.size(),'Deberían haberse actualizado el numero de Installments en Promise');
    }

    @IsTest
    static void testErrorMessage_ExceedPricingValues() {

        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);

        Pricing__c pricing = TestFactory.createSinglePricing(debt, true, 30, 12, 10, 25, 15, 20);
        pricing.MinAmountInstallment_NUM__c = 100;
        update pricing;
        
        Test.startTest();
        try {
            // Caso 1: Número de cuotas superior al máximo permitido
            Promise__c promise = new Promise__c(
            Debt_REL__c = debt.Id,
            LastPromise_BOL__c = true,
            StartDate_DAT__c = Date.today(),
            PaymentDayOfMonth_SEL__c = '5',
            Frequency_SEL__c = 'Monthly',
            PartialPayment_BOL__c = false,
            TotalAmountPromised__c = 9800,
            NumberOfInstallments__c = 14,
            InstallmentsAmount__c = 150,
            PaymentPlanSelected_SEL__c = 'Custom'
            );
            insert promise;

            System.assert(false, 'Debe lanzar error para los casos inválidos');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains(Label.Error_Promise_MaxNumInstallment),
                         'El mensaje de error debe provenir de los labels configurados');
        }
        try {
            // Caso 2: Importe menor al mínimo permitido
            Promise__c promise = new Promise__c(
            Debt_REL__c = debt.Id,
            LastPromise_BOL__c = true,
            StartDate_DAT__c = Date.today(),
            PaymentDayOfMonth_SEL__c = '5',
            Frequency_SEL__c = 'Monthly',
            PartialPayment_BOL__c = false,
            TotalAmountPromised__c = 9800,
            NumberOfInstallments__c = 8,
            InstallmentsAmount__c = 80,
            PaymentPlanSelected_SEL__c = 'Custom'
            );
            insert promise;

            System.assert(false, 'Debe lanzar error para los casos inválidos');
        } catch (DmlException e) {
            // Verificamos los errores esperados
            System.assert(e.getMessage().contains(Label.Error_Promise_MinAmountInstallment),
                         'El mensaje de error debe provenir de los labels configurados');
        }
        
        // Caso 3: Todo correcto
        Promise__c promiseCorrectInstallments = TestFactory.createSinglePromise(debt, true, 9800, 100, 8, false, 'Custom');
        Test.stopTest();  
        System.assertNotEquals(null, promiseCorrectInstallments.Id, 
        'La promesa válida debería haberse insertado correctamente');      
    }


    @isTest
    static void testAux() {
        Automation_Settings__c setting = TestFactory.customSetting();
        
        PromiseHandler handler = new PromiseHandler(0);
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