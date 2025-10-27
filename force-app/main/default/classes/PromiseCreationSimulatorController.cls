/**
 * @description       : PromiseCreationSimulatorController Class
 * @author            : Horizon CX
 * @last modified on  : 23/10/2025
 * @last modified by  : Horizon CX
 *      - 23/10/2025  : Creation. Clase controladora del LWC llamado promiseCreationSimulator
**/
public with sharing class PromiseCreationSimulatorController {
    @AuraEnabled(cacheable=true)
    public static Debt__c getDebtId(Id recordId, String objectApiName) {
        System.debug('getDebtId: recordId: ' + recordId + ', objectApiName: ' + objectApiName);
        
        if (objectApiName == 'Case') {
            Id debtId = [SELECT Id, Debt_REL__c FROM Case WHERE Id = :recordId LIMIT 1].Debt_REL__c;
            return getDebtInfo(debtId);

        } else if (objectApiName == 'VoiceCall') {
            Id debtId = [SELECT Id, Debt_REL__c FROM VoiceCall WHERE Id = :recordId LIMIT 1].Debt_REL__c;
            return getDebtInfo(debtId);
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static Debt__c getDebtInfo(Id debtId) {
        System.debug('getDebtInfo: debtId: ' + debtId);
        if(debtId == null){
            throw new AuraHandledException('Debe seleccionar una deuda antes de poder continuar');
        }
        Debt__c debt = [SELECT Id, Name, TotalAmount__c, TotalPending_FOR__c, NegociationB_FOR__c, MaxDiscount_AmountAvailableFP_CUR__c, NegociationA_FOR__c, MaxDiscount_AmountAvailablePP_CUR__c
                        FROM Debt__c 
                        WHERE Id = :debtId 
                        LIMIT 1];

        if (debt == null) {
            throw new AuraHandledException('Se ha producido un error al recuperar la info de la Deuda');
        }else{
            System.debug('debt:  '+debt);
            return debt;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Pricing__c getPricingInfo(Id debtId) {
        System.debug('getPricingInfo: debtId: ' + debtId);

        if(debtId == null){
            throw new AuraHandledException('Debe seleccionar una deuda antes de poder continuar');
        }

        Debt__c debt = [SELECT Id, Pricing_REL__c FROM Debt__c WHERE Id = :debtId LIMIT 1];
        if (debt.Pricing_REL__c == null) {
            throw new AuraHandledException('La deuda seleccionada no tiene asociado un Pricing');
        }

        Pricing__c pricing = [SELECT MaxInstallmentsActive_NUM__c, MinAmountInstallment_NUM__c 
                                FROM Pricing__c 
                                WHERE Id = :debt.Pricing_REL__c 
                                AND IsActive_BOL__c = true
                                LIMIT 1];
        if (pricing == null) {
            throw new AuraHandledException('El Pricing asociado a la deuda no está activo');
        }else{
            System.debug('Pricing:  '+[SELECT MaxInstallmentsActive_NUM__c, MinAmountInstallment_NUM__c FROM Pricing__c WHERE Id = :debt.Pricing_REL__c LIMIT 1]);
            return [SELECT MaxInstallmentsActive_NUM__c, MinAmountInstallment_NUM__c FROM Pricing__c WHERE Id = :debt.Pricing_REL__c LIMIT 1];
        }
    }

    @AuraEnabled
    public static List<PromisesInstallment__c> simulatePromise(Id debtId, Map<String, Object> promiseData) {
        System.debug('debtId: '+debtId + 'promiseData: '+promiseData);
        if(debtId == null){
            throw new AuraHandledException('Debe seleccionar una deuda antes de poder crear la promesa.');
        }

        Debt__c debt = [SELECT Id, Pricing_REL__c FROM Debt__c WHERE Id = :debtId LIMIT 1];
        if (debt.Pricing_REL__c == null) {
            throw new AuraHandledException('La deuda seleccionada no tiene asociado un Pricing válido.');
        }

        Pricing__c pricing = [SELECT MaxInstallmentsActive_NUM__c, MinAmountInstallment_NUM__c FROM Pricing__c WHERE Id = :debt.Pricing_REL__c LIMIT 1];

        //Integer numInstallments = (Integer)promiseData.get('NumberOfInstallments__c');
        Integer numInstallments;
        Object objNumInstallments = promiseData.get('NumberOfInstallments__c');
        if (objNumInstallments != null) {
            numInstallments = ((Decimal)objNumInstallments).intValue();
        }
        Date startDay = Date.valueOf((String)promiseData.get('StartDate_DAT__c'));
        Decimal totalAmountPromise = (Decimal)promiseData.get('TotalAmountPromised__c');
        Decimal installmentAmount = (Decimal)promiseData.get('InstallmentsAmount__c');
        String paymentDayOfMonth = (String) promiseData.get('PaymentDayOfMonth_SEL__c');
        Boolean partialPayment = (Boolean)promiseData.get('PartialPayment_BOL__c');
        String paymentMethod = (String)promiseData.get('PaymentMethod_SEL__c');

        if (numInstallments == null && installmentAmount == null) {
            throw new AuraHandledException('Se debe rellenar el campo "Número de cuotas" o "Importe de la cuota" para poder continuar');
        }

        // Validaciones de límites
        if (numInstallments != null && pricing.MaxInstallmentsActive_NUM__c != null && numInstallments > pricing.MaxInstallmentsActive_NUM__c) {
            throw new AuraHandledException(Label.Error_Promise_MaxNumInstallment);
        }
        if (installmentAmount != null && pricing.MinAmountInstallment_NUM__c != null && installmentAmount < pricing.MinAmountInstallment_NUM__c) {
            throw new AuraHandledException(Label.Error_Promise_MinAmountInstallment);
        }

        // Calcular cuotas simuladas
        return calculationPromisesInstallment(
            totalAmountPromise, numInstallments, installmentAmount, startDay, paymentDayOfMonth, partialPayment, paymentMethod, debtId
        );
    }

    public static List<PromisesInstallment__c> calculationPromisesInstallment(
        Decimal totalAmountPromise, 
        Integer numInstallments, 
        Decimal installmentAmount, 
        Date startDay,
        String paymentDayOfMonth,
        Boolean partialPayment,
        String paymentMethod,
        Id debtId) {

        List<PromisesInstallment__c> installmentsList = new List<PromisesInstallment__c>();

        // Validaciones básicas
        if (totalAmountPromise == null || debtId == null) {
            throw new AuraHandledException('Los parámetros Total importe promesa y Deuda relacionada son obligatorios.');
        }

        // Definir variables
        Date rawDate;
        Integer paymentDay = String.isNotBlank(paymentDayOfMonth) ? Integer.valueOf(paymentDayOfMonth) : null;
        Date startDate = startDay;

        Decimal totalAmount = totalAmountPromise;
        Integer numOfInstallments = numInstallments != null ? Integer.valueOf(numInstallments) : 0;
        Decimal baseAmount = installmentAmount != null ? installmentAmount : 0;
        
        if((numInstallments == null || numInstallments == 0) && installmentAmount != null){
            Decimal num;   
            num = totalAmount / installmentAmount;
            numOfInstallments = num.intValue() + 1;
        }else{
            numOfInstallments = numInstallments;
        }
        if((installmentAmount == null || installmentAmount == 0) && numInstallments != null){
            baseAmount = totalAmount / numOfInstallments;
        }else{
            baseAmount = installmentAmount;
        }
        
        //Full payment
        if((numOfInstallments != null && numOfInstallments == 1) || totalAmount == baseAmount){
            PromisesInstallment__c installment = new PromisesInstallment__c();
                installment.Debt_REL__c = debtId;
                installment.PaymentDate__c = startDate;
                installment.NInstallments__c = 1;
                installment.InstallmentsAmount__c = totalAmount;

                installmentsList.add(installment);
        }
        //Payment plan 
        else {
            System.debug('Dentro Else numOfInstallments:  '+numOfInstallments);
            for (Integer i = 0; i < numOfInstallments; i++) {
                System.debug('Dentro for i:  '+i);
                if(!String.isBlank(paymentDayOfMonth)){
                    if (i == 0) {
                        // Primera cuota = StartDate
                        rawDate = startDate;
                    } else {
                        // Cuotas siguientes = día elegido cada mes
                        Date targetMonth = startDate.addMonths(i);
                        Integer daysInTargetMonth = Date.daysInMonth(targetMonth.year(), targetMonth.month());
                        Integer validDay = (paymentDay != null) ? Math.min(paymentDay, daysInTargetMonth) : targetMonth.day();
                        rawDate = Date.newInstance(targetMonth.year(), targetMonth.month(), validDay);
                    }
                }else{
                    rawDate = startDate.addMonths(i);
                }

                Date adjustedDate = PromiseHelper.adjustToBusinessDay(rawDate);
                System.debug('adjustedDate:  '+adjustedDate);

                PromisesInstallment__c installment = new PromisesInstallment__c();
                    installment.Debt_REL__c = debtId;
                    installment.PaymentDate__c = adjustedDate;
                    installment.NInstallments__c = i + 1;

                // Custom: ajustar última cuota
                if (i == numOfInstallments - 1) {
                    installment.InstallmentsAmount__c =  totalAmount - (baseAmount * (numOfInstallments - 1));
                    System.debug('If Amount  '+installment.InstallmentsAmount__c);
                } else {
                    installment.InstallmentsAmount__c = baseAmount;
                    System.debug('else Amount  '+installment.InstallmentsAmount__c);
                }
                System.debug('installment:  '+installment);

                installmentsList.add(installment);
            }
        }
        return installmentsList;
    }

    @AuraEnabled
    public static Id createPromiseWithInstallments(Promise__c promiseData) {
        if (promiseData == null) {
            throw new AuraHandledException('No se ha proporcionado información de la Promesa.');
        }
        try {
            insert promiseData;
            return promiseData.Id;
        } catch (DmlException e) {
            System.debug('Error al crear la Promesa desde el Simulador: ' + e.getMessage());
            throw new AuraHandledException('Error al crear la Promesa: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            System.debug('Error inesperado: ' + e.getMessage());
            throw new AuraHandledException('Error inesperado al crear la Promesa: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Debt__c> searchDebts(String searchKey) {
        // Evitar consultas con texto vacío
        if (String.isBlank(searchKey)) {
            return new List<Debt__c>();
        }

        // Consulta SOQL: devolver Id y Name de las deudas que coincidan con el texto
        return [
            SELECT Id, Name, TotalAmount__c
            FROM Debt__c
            WHERE Name LIKE :('%' + searchKey + '%')
            ORDER BY Name
            LIMIT 20
        ];
    }
}