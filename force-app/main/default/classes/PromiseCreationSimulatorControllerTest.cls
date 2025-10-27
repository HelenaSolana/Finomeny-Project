/**
 * @description       : PromiseCreationSimulatorControllerTest Class
 * @author            : Horizon CX
 * @last modified on  : 27/10/2025
 * @last modified by  : Horizon CX
**/
@isTest
private class PromiseCreationSimulatorControllerTest {

    @IsTest
    static void testGetDebtIdAndDebtInfo() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Pricing__c pricing = TestFactory.createSinglePricing(debt, true, 20, 12, 15, 18, 10, 15);
        pricing.MinAmountInstallment_NUM__c = 150;
        update pricing;

        Case testCase = new Case(Debt_REL__c = debt.Id, Subject = 'Test Case');
        insert testCase;

        Test.startTest();
        Debt__c debtResult = PromiseCreationSimulatorController.getDebtId(testCase.Id, 'Case');
        System.assertNotEquals(null, debtResult);
        System.assertEquals(debt.Id, debtResult.Id);

        Debt__c debtInfo = PromiseCreationSimulatorController.getDebtInfo(debt.Id);
        System.assertNotEquals(null, debtInfo);
        System.assertEquals(debt.Name, debtInfo.Name);
        Test.stopTest();
    }

    @IsTest
    static void testGetPricingInfo() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Pricing__c pricing = TestFactory.createSinglePricing(debt, true, 20, 12, 15, 18, 10, 15);
        pricing.MinAmountInstallment_NUM__c = 150;
        update pricing;

        Test.startTest();
        Pricing__c pricingResult = PromiseCreationSimulatorController.getPricingInfo(debt.Id);
        System.assertNotEquals(null, pricingResult);
        System.assertEquals(pricing.MaxInstallmentsActive_NUM__c, pricingResult.MaxInstallmentsActive_NUM__c);
        Test.stopTest();
    }

    @IsTest
    static void testSimulatePromiseSuccess() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Pricing__c pricing = TestFactory.createSinglePricing(debt, true, 20, 12, 15, 18, 10, 15);
        pricing.MinAmountInstallment_NUM__c = 150;
        update pricing;
        Date d = Date.today();
        String monthStr = d.month() < 10 ? '0' + d.month() : String.valueOf(d.month());
        String dayStr = d.day() < 10 ? '0' + d.day() : String.valueOf(d.day());
        String startDateStr = d.year() + '-' + monthStr + '-' + dayStr;

        Map<String, Object> promiseData = new Map<String, Object>{
            'StartDate_DAT__c' => startDateStr,
            'TotalAmountPromised__c' => 1000,
            'InstallmentsAmount__c' => 220,
            'PaymentDayOfMonth_SEL__c' => '15',
            'PartialPayment_BOL__c' => false,
            'PaymentMethod_SEL__c' => 'Credit Card'
        };

        Test.startTest();
        List<PromisesInstallment__c> installments = PromiseCreationSimulatorController.simulatePromise(debt.Id, promiseData);
        System.assertEquals(5, installments.size(), 'Debe crear 5 cuotas (4x220 y 1x120)');
        Test.stopTest();
    }

    @IsTest
    static void testCalculationPromisesInstallmentFullPayment() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Pricing__c pricing = TestFactory.createSinglePricing(debt, true, 20, 12, 15, 18, 10, 15);
        pricing.MinAmountInstallment_NUM__c = 150;
        update pricing;

        List<PromisesInstallment__c> installments = PromiseCreationSimulatorController.calculationPromisesInstallment(
            1000, 1, null, Date.today(), null, false, 'Cash', debt.Id
        );
        System.assertEquals(1, installments.size());
        System.assertEquals(1000, installments[0].InstallmentsAmount__c);
    }

    @IsTest
    static void testCreatePromiseWithInstallments() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Pricing__c pricing = TestFactory.createSinglePricing(debt, true, 20, 12, 15, 18, 10, 15);
        pricing.MinAmountInstallment_NUM__c = 150;
        update pricing;

        Promise__c promise = new Promise__c(
            Debt_REL__c = debt.Id,
            TotalAmountPromised__c = 1000,
            PaymentMethod_SEL__c = 'Credit Card',
            PaymentDayOfMonth_SEL__c = '15',
            Frequency_SEL__c = 'Monthly',
            LastPromise_BOL__c = true,
            InstallmentsAmount__c = 220,
            NumberOfInstallments__c = 4,
            PartialPayment_BOL__c = false,
            StartDate_DAT__c = Date.today()
        );

        Test.startTest();
        Id promiseId = PromiseCreationSimulatorController.createPromiseWithInstallments(promise);
        System.assertNotEquals(null, promiseId);
        Test.stopTest();
    }

    @IsTest
    static void testSearchDebts() {
        Automation_Settings__c setting = TestFactory.customSetting();
        Account client = TestFactory.createSingleClient();
        Portfolio__c portfolio = TestFactory.createSinglePortfolio(client);
        insert portfolio;
        Debt__c debt = TestFactory.createSingleDebt(portfolio, 10000);
        Pricing__c pricing = TestFactory.createSinglePricing(debt, true, 20, 12, 15, 18, 10, 15);
        pricing.MinAmountInstallment_NUM__c = 150;
        update pricing;

        Test.startTest();
        List<Debt__c> result = PromiseCreationSimulatorController.searchDebts('Debt Prueba');
        System.assert(result.size() > 0);
        System.assertEquals(debt.Id, result[0].Id);
        Test.stopTest();
    }
}