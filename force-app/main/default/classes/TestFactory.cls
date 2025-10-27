/**
 * @name              : TestFactory
 * @author            : Horizon CX
 * @last modified on  : 06/08/2025
 * @description       : Clase Apex Test Factory que será usada para la creación de registros que se utilizarán en el resto de clases test de la organización
 */
@isTest
public class TestFactory {

    public static Id clientRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
    public static Id customerRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

    // Configurar el custom setting para el usuario de test
    public static Automation_Settings__c customSetting(){
        Automation_Settings__c settings = new Automation_Settings__c(
            SetupOwnerId = UserInfo.getUserId(), 
            Triggers_Enabled__c = true
        );
        insert settings;
        return settings;
    }
    
    public static Account createSingleClient() {
        Account acc = new Account(
            Name = 'Client Prueba',
            RecordTypeId = clientRTId
        );
        insert acc;
        return acc;
    }

    public static List<Account> createMultipleClients(Integer numClients) {
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < numClients; i++) {
            accList.add(new Account(
                Name = 'Client Prueba ' + i,
                RecordTypeId = clientRTId
            ));
        }
        insert accList;
        return accList;
    }

    public static Account createSingleCustomers() {
        Account acc = new Account(
            FirstName = 'Customer',
            LastName = 'Prueba',
            RecordTypeId = customerRTId
        );
        insert acc;
        return acc;
    }

    public static List<Account> createMultipleCustomers(Integer numCustomers) {
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < numCustomers; i++) {
            accList.add(new Account(
                FirstName = 'Customer',
                LastName = 'Prueba ' + i,
                RecordTypeId = customerRTId
            ));
        }
        insert accList;
        return accList;
    }
 
    public static Portfolio__c createSinglePortfolio(Account acc) {
        Portfolio__c portfolio = new Portfolio__c(
            Name = 'Portfolio Prueba',
            Client_REL__c = acc.Id,
            N_assignment_SEL__c = '1'
        );
        //insert portfolio;
        return portfolio;
    }

    public static List<Portfolio__c> createMultiplePortfolios(List<Account> accList) {
        List<Portfolio__c> portfolios = new List<Portfolio__c>();
        for (Integer i = 0; i < accList.size(); i++) {
            portfolios.add(new Portfolio__c(
                Name = 'Portfolio Prueba ' + i,
                Client_REL__c = accList[i].Id,
                N_assignment_SEL__c = '1'
            ));
        }
        //insert portfolios;
        return portfolios;
    }

    public static Debt__c createSingleDebt(Portfolio__c portfolio, Decimal amount) {
        Debt__c debt = new Debt__c(
            Name = 'Debt Prueba',
            Portfolio_REL__c = portfolio.Id,
            Status_SEL__c = 'Open',
            TotalAmount__c = amount
        );
        insert debt;
        return debt;
    }

    public static List<Debt__c> createMultipleDebts(Portfolio__c portfolio, Decimal amount, Integer numPortfolios) {
        List<Debt__c> debts = new List<Debt__c>();
        for (Integer i = 0; i < numPortfolios; i++) {
            debts.add(new Debt__c(
                Name = 'Debt Prueba '+ i,
                Portfolio_REL__c = portfolio.Id,
                Status_SEL__c = 'Open',
                TotalAmount__c = amount
            ));
        }
        insert debts;
        return debts;
    }

    public static DebtCustomer__c createSingleDebtCustomerRelation(Debt__c debt, Account customer) {
        DebtCustomer__c debtCustomer = new DebtCustomer__c(
            Debt_REL__c = debt.Id,
            Customer_REL__c = customer.Id
        );
        insert debtCustomer;
        return debtCustomer;
    }

    public static List<DebtCustomer__c> createMultipleDebtCustomerRelations(List<Debt__c> debts, List<Account> customers) {
        List<DebtCustomer__c> debtCustomerList = new List<DebtCustomer__c>();
    
        // Asegurarse de que ambas listas tienen la misma longitud
        Integer minSize = Math.min(debts.size(), customers.size());
    
        for (Integer i = 0; i < minSize; i++) {
            debtCustomerList.add(new DebtCustomer__c(
                Debt_REL__c = debts[i].Id,
                Customer_REL__c = customers[i].Id
            ));
        }
    
        insert debtCustomerList;
        return debtCustomerList;
    }

    public static ContactData__c createSingleContactData(Debt__c debt, Account customer, String typeData, String value, Boolean valid, Boolean contactable, Integer score) {
        ContactData__c data = new ContactData__c(
            Debt_REL__c = debt.Id,
            Customer_REL__c = customer.Id,
            IsValid__c = valid,
            IsContactable__c = contactable,
            ContactDataType_SEL__c = typeData, // Valores posibles: Email, Phone, MobilePhone, Address, Social Media
            ContactDataValue__c = value,
            PriorityScore_NUM__c = score
        );
        insert data;
        return data;
    }

    public static Pricing__c createSinglePricing(Debt__c debt, Boolean isActive, Decimal maxDiscount, Decimal maxInstallmentActive, Integer maxInstallments, Decimal maxDiscountAvailable, Decimal maxDiscountPP, Decimal maxDiscountFP) {
        Pricing__c pricing = new Pricing__c(
            Debt_REL__c = debt.Id,
            MaxDiscount_PER__c = maxDiscount,
            MaxInstallmentsActive_NUM__c = maxInstallmentActive,
            MaximumInstallments_NUM__c = maxInstallments,
            MaximumDiscountAvailable_PER__c = maxDiscountAvailable,
            DiscountForPaymentPlan_PER__c = maxDiscountPP,
            DiscountforfullPayment_PER__c = maxDiscountFP,
            IsActive_BOL__c = isActive
        );
        insert pricing;
        return pricing;
    }

    public static Promise__c createSinglePromise(Debt__c debt, Boolean lastPromise, Decimal totalAmountPromise, Decimal amountPromise, Integer numInstallment, Boolean partialPayment, String type) {
        Promise__c promise = new Promise__c(
            Debt_REL__c = debt.Id,
            LastPromise_BOL__c = lastPromise,
            StartDate_DAT__c = Date.today(),
            PaymentDayOfMonth_SEL__c = '5',
            Frequency_SEL__c = 'Monthly',
            PartialPayment_BOL__c = partialPayment,
            TotalAmountPromised__c = totalAmountPromise,
            NumberOfInstallments__c = numInstallment,
            InstallmentsAmount__c = amountPromise,
            PaymentPlanSelected_SEL__c = type
        );
        insert promise;
        return promise;
    }

    public static Payment__c createSinglePayment(Debt__c debt, Decimal amount) {
        Payment__c pay = new Payment__c(
            Debt_REL__c = debt.Id,
            TransactionAmount__c  = amount,
            Transactiondirection_SEL__c = 'Received'
        );
        insert pay;
        return pay;
    }
    public static Payment__c createSinglePaymentReturned(Debt__c debt, Decimal amount) {
        Payment__c pay = new Payment__c(
            Debt_REL__c = debt.Id,
            TransactionAmount__c  = amount,
            Transactiondirection_SEL__c = 'Returned'
        );
        insert pay;
        return pay;
    }

    public static Payment__c createSinglePaymentWithPromise(Debt__c debt, Promise__c promise, PromisesInstallment__c installmet, Decimal amount) {
        Payment__c pay = new Payment__c(
            Debt_REL__c = debt.Id,
            Promise_REL__c = promise.Id,
            PromisesInstallment_REL__c = installmet.Id,
            TransactionAmount__c  = amount,
            Transactiondirection_SEL__c = 'Received'
        );
        insert pay;
        return pay;
    }

    public static Judicial__c createSingleJudicial(Debt__c debt) {
        Judicial__c judicial = new Judicial__c(
            Debt_REL__c = debt.Id,
            ProcessStatus__c  = 'Ongoing'
        );
        insert judicial;
        return judicial;
    }

    public static Case createSingleCaseByOrigen(Account acc, String origen) {
        Case caso = new Case(
            AccountId = acc.Id,
            Origin = origen,
            CaseOrigin_SEL__c = origen
        ); 
        return caso;
    }
}