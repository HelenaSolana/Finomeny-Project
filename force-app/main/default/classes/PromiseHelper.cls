/**
 * @description       : PromiseHelper Class
 * @author            : Horizon CX
 * @last modified on  : 05/09/2025
 * @last modified by  : Horizon CX
 *      - 06/10/2025  : Añadir el campo "Payment Day of Month" a los calculos creación de installments (method createPromisesInstallment)
**/
public without sharing class PromiseHelper {
    /**
     * @description Método que crea los registros de Promise Installments asociados a la Promise cuando se crea
     * @param List<Promise__c> newRecordList
     * @return void
     */
    public static void createPromisesInstallment(List<Promise__c> newRecordList) {
        List<PromisesInstallment__c> installmentsToInsert = new List<PromisesInstallment__c>();

        for (Promise__c newRec : newRecordList) {
            Date startDate = newRec.StartDate_DAT__c != null ? newRec.StartDate_DAT__c : Date.today();
            String paymentDayStr = newRec.PaymentDayOfMonth_SEL__c;

            // Convertir PaymentDay a Integer si existe
            Integer paymentDayInt = (!String.isBlank(paymentDayStr)) ? Integer.valueOf(paymentDayStr) : null;

            Integer numOfInstallments = newRec.NumberOfInstallments__c != null ? Integer.valueOf(newRec.NumberOfInstallments__c) : 0;
            Decimal baseAmount = newRec.InstallmentsAmount__c != null ? newRec.InstallmentsAmount__c : 0;

            // FULL PAYMENT
            if((numOfInstallments != null && numOfInstallments == 1) || newRec.TotalAmountPromised__c == newRec.InstallmentsAmount__c){
                PromisesInstallment__c installment = new PromisesInstallment__c();
                installment.Promise_REL__c = newRec.Id;
                installment.Debt_REL__c = newRec.Debt_REL__c;
                installment.PaymentDate__c = startDate;
                installment.IsActive_BOL__c = true;
                installment.NInstallments__c = 1;
                installment.InstallmentsAmount__c = baseAmount;

                installmentsToInsert.add(installment);
            }
            // PAYMENT PLAN
            else{

            for (Integer i = 0; i < numOfInstallments; i++) {
                Date rawDate;
                /*if (frequency == 'Weekly') {
                    rawDate = startDate.addDays(i * 7);
                } else {
                    // Por defecto, mensual
                    rawDate = startDate.addMonths(i);
                }*/

                if(!String.isBlank(paymentDayStr)){
                    if (i == 0) {
                        // Primera cuota = StartDate
                        rawDate = startDate;
                    } else {
                        // Cuotas siguientes = día elegido cada mes
                        Date targetMonth = startDate.addMonths(i);
                        Integer daysInTargetMonth = Date.daysInMonth(targetMonth.year(), targetMonth.month());
                        Integer validDay = (paymentDayInt != null) ? Math.min(paymentDayInt, daysInTargetMonth) : targetMonth.day();
                        rawDate = Date.newInstance(targetMonth.year(), targetMonth.month(), validDay);
                    }
                }else{
                    rawDate = startDate.addMonths(i);
                }

                Date adjustedDate = adjustToBusinessDay(rawDate);

                PromisesInstallment__c installment = new PromisesInstallment__c();
                installment.Promise_REL__c = newRec.Id;
                installment.Debt_REL__c = newRec.Debt_REL__c;
                installment.PaymentDate__c = adjustedDate;
                installment.IsActive_BOL__c = true;
                installment.NInstallments__c = i + 1;

                // Asignar importe
                if (newRec.PaymentPlanSelected_SEL__c == 'Predefined') {
                    installment.InstallmentsAmount__c = baseAmount;
                } else {
                    // Custom: ajustar última cuota
                    if (i == numOfInstallments - 1) {
                        installment.InstallmentsAmount__c = newRec.TotalAmountPromised__c - (baseAmount * (numOfInstallments - 1));
                    } else {
                        installment.InstallmentsAmount__c = baseAmount;
                    }
                }

                installmentsToInsert.add(installment);
            }
            }
        }

        if (!installmentsToInsert.isEmpty()) {
            try {
                insert installmentsToInsert;
            } catch (DmlException e) {
                System.debug('Error al crear las Promise Installments: ' + e.getMessage());
            }
        }
    }
    /**
     * @description Método que usado para calcular las fechas de cada Promise Instalment
     * Si la fecha resultante cae en sábado, se ajusta al viernes anterior, siempre que esté en el mismo mes.
     * Si cae en domingo, se ajusta al lunes siguiente, siempre que esté en el mismo mes.
     * @param Date startDate
     * @return adjustedDate
     */
    public static Date adjustToBusinessDay(Date startDate) {
        Integer dayOfWeek = getDayOfWeek(startDate);
        Date adjustedDate = startDate;
    
        if (dayOfWeek == 5) { // Sábado
            Date tentativeDate = startDate.addDays(-1);
            Date nextDay = startDate.addDays(2); // lunes siguiente
            if (tentativeDate.month() == startDate.month()) {
                // Si viernes es mismo mes, se mueve atrás
                adjustedDate = tentativeDate;
            } else {
                // Si viernes es mes anterior, se mueve al lunes siguiente
                adjustedDate = nextDay;
            }
        } else if (dayOfWeek == 6) { // Domingo
            Date tentativeDate = startDate.addDays(1); // lunes siguiente
            if (tentativeDate.month() == startDate.month()) {
                adjustedDate = tentativeDate;
            } else {
                // Si lunes siguiente es mes siguiente, se mueve al viernes anterior
                Date fridayDate = startDate.addDays(-2);
                if (fridayDate.month() == startDate.month()) {
                    adjustedDate = fridayDate;
                }
                // Si tampoco es mismo mes, mantiene domingo
            }
        }
        // No cambia si es lunes a viernes
        return adjustedDate;
    }

    public static Integer getDayOfWeek(Date dateStart) {
        DateTime dt = DateTime.newInstance(dateStart, Time.newInstance(0, 0, 0, 0));
        String dayStr = dt.format('u', 'en_US');  // 1 = lunes ... 7 = domingo
        return Integer.valueOf(dayStr);
    }

    /**
     * @description Método que actualiza el campo "Broken Date" de Promise cuando se actualiza el campo Status a "Broken"
     *              Se actualiza el campo "Write Off Amount" de la Deuda asociada una Promesa a cero cuando la Promesa pasa a "Broken"
     * @param List<Promise__c> newRecordList
     * @param Map<Id,Promise__c> oldRecordMap
     * @return void
     */
    public static void updateBrokenDate(List<Promise__c> newRecordList, Map<Id, Promise__c> oldRecordMap) {
        List<Promise__c> promiseToUpdate =  new List<Promise__c>();
        List<Debt__c> debtToUpdate =  new List<Debt__c>();
        Set<Id> debtId = new Set<Id>();

        for (Promise__c promise : newRecordList) {
            if (promise.Debt_REL__c != null) {
                debtId.add(promise.Debt_REL__c);
            }
        }
        Map<Id,Debt__c> debtMap = new Map<Id, Debt__c>(
                [SELECT Id, WriteOffAmount__c  
                FROM Debt__c 
                WHERE Id 
                IN :debtId]);

        for (Promise__c newRec : newRecordList) {
            Promise__c oldRec = oldRecordMap.get(newRec.Id);

            if (newRec.StatusPotential_SEL__c == 'Broken' && newRec.StatusPotential_SEL__c != oldRec.StatusPotential_SEL__c && debtMap.containsKey(newRec.Debt_REL__c)) {
                promiseToUpdate.add(new Promise__c(
                    Id = newRec.Id, 
                    BrokenDate__c = System.today()
                ));

                Debt__c relatedDebt = debtMap.get(newRec.Debt_REL__c);
                relatedDebt.WriteOffAmount__c = 0;
                debtToUpdate.add(relatedDebt);
            }
        }
        //Se llama al método que desactiva las Promise Installments asociadas a la Promise en estado Broken
        updatePromiseInstallments_Inactive(promiseToUpdate);

        if (!promiseToUpdate.isEmpty() && !debtToUpdate.isEmpty()) {
            try {
                update promiseToUpdate;
                update debtToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar el campo "Broken Date" en Promise' + e.getMessage());
            }
        }
    }

    /**
     * @description Método que, cuando se crea una nueva Promise con el campo "Last Promise" a TRUE, actualiza el campo "Last Promise" a False del resto de Promises asociadas a la Debt
     * @param List<Promise__c> newRecordList
     * @return void
     */
    public static void updateLastPromisesCheck(List<Promise__c> newRecordList) {
        List<Promise__c> promisesToUpdate =  new List<Promise__c>();
        Set<Id> debtId = new Set<Id>();
        Map<Id, Id> newLastPromiseIdsByDebt = new Map<Id, Id>();

        for (Promise__c promise : newRecordList) {
            if (promise.Debt_REL__c != null && promise.LastPromise_BOL__c) {
                debtId.add(promise.Debt_REL__c);
                newLastPromiseIdsByDebt.put(promise.Debt_REL__c, promise.Id);
            }
        }
        if (debtId.isEmpty()) return;

        List<Promise__c> promisesRelated = new List<Promise__c>(
                [SELECT Id, LastPromise_BOL__c, Debt_REL__c 
                FROM Promise__c 
                WHERE Debt_REL__c IN :debtId AND LastPromise_BOL__c = TRUE]);

        for (Promise__c existing : promisesRelated) {
            // Excluimos de la actualización la Promise nueva 
            Id newPromiseId = newLastPromiseIdsByDebt.get(existing.Debt_REL__c);
            if (existing.Id != newPromiseId) {
                existing.LastPromise_BOL__c = false;
                promisesToUpdate.add(existing);
            }
        }
        
        //Se llama al método que desactiva las Promise Installments asociadas a las Promise que se desactivan
        updatePromiseInstallments_Inactive(promisesToUpdate);

        if (!promisesToUpdate.isEmpty()) {
            try {
                update promisesToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar el campo "Last Promise" en las Promises relacionadas: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Método que actualiza el campo "Status Potencial" de Promise cuando se actualiza el campo "Pending Amount" a cero
     * @param List<Promise__c> newRecordList
     * @param Map<Id,Promise__c> oldRecordMap
     * @return void
     */
    public static void updateStatusPromise(List<Promise__c> newRecordList, Map<Id, Promise__c> oldRecordMap) {
        List<Promise__c> promiseToUpdate =  new List<Promise__c>();
    
        for (Promise__c newRec : newRecordList) {
            Promise__c oldRec = oldRecordMap.get(newRec.Id);

            if (newRec.PendingAmount_FOR__c != oldRec.PendingAmount_FOR__c && newRec.PendingAmount_FOR__c == 0 && newRec.StatusPotential_SEL__c != 'Paid' ) {
                promiseToUpdate.add(new Promise__c(
                    Id = newRec.Id, 
                    StatusPotential_SEL__c = 'Paid'
                ));
            }
        }
        if (!promiseToUpdate.isEmpty()) {
            try {
                update promiseToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar el campo "Broken Date" en Promise' + e.getMessage());
            }
        }
    }

    /**
     * @description Método que actualiza el campo "Write Off Amount" de la Deuda asociada una Promesa, cuando está es la ultima y no tiene la Broken Date rellena. 
     *              Excepto cuando la Promise es Partial payment
     * @param List<Promise__c> newRecordList
     * @return void
     */
    public static void updateDebt_WriteOffAmount(List<Promise__c> newRecordList) {
        List<Debt__c> debtToUpdate =  new List<Debt__c>();
        Set<Id> debtId = new Set<Id>();

        for (Promise__c promise : newRecordList) {
            if (promise.Debt_REL__c != null) {
                debtId.add(promise.Debt_REL__c);
            }
        }
        Map<Id,Debt__c> debtMap = new Map<Id, Debt__c>(
                [SELECT Id, WriteOffAmount__c  
                FROM Debt__c 
                WHERE Id 
                IN :debtId]);

        for (Promise__c newRec : newRecordList) {

            if (newRec.LastPromise_BOL__c && newRec.BrokenDate__c == null 
                && !newRec.PartialPayment_BOL__c && debtMap.containsKey(newRec.Debt_REL__c)) {
                Debt__c relatedDebt = debtMap.get(newRec.Debt_REL__c);

                relatedDebt.WriteOffAmount__c = newRec.WriteOffAmount_CUR__c;
                debtToUpdate.add(relatedDebt);
            }
        }

        if (!debtToUpdate.isEmpty()) {
            try {
                update debtToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar el campo "Write Off Amount" en Debt: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Método que, cuando se crea una nueva Promise actualiza el campo "Write off amount" de la Promise.
     *              Excepto cuando la Promise es Partial payment
     * @param List<Promise__c> newRecordList
     * @return void
     */
    public static void updatePromise_WriteOffAmount(List<Promise__c> newRecordList) {
        if (newRecordList == null || newRecordList.isEmpty()) {
            return;
        }
        List<Promise__c> promiseToUpdate =  new List<Promise__c>();
        Set<Id> debtId = new Set<Id>();

        for (Promise__c promise : newRecordList) {
            if (promise.Debt_REL__c != null) {
                debtId.add(promise.Debt_REL__c);
            }
        }
        if (debtId.isEmpty()) {
            return;
        }

        Map<Id,Debt__c> debtMap = new Map<Id, Debt__c>(
                [SELECT Id, TotalAmount__c  
                FROM Debt__c 
                WHERE Id 
                IN :debtId]);
        
        for (Promise__c newRec : newRecordList) {
            Debt__c relatedDebt = debtMap.get(newRec.Debt_REL__c);

            System.debug(LoggingLevel.DEBUG, 'Promise=' + newRec + ' | Debt in map? ' + debtMap.containsKey(newRec.Debt_REL__c) + ' | relatedDebt.TotalAmount__c=' + (relatedDebt==null?null:relatedDebt.TotalAmount__c) + ' | newRec.TotalAmountPromised__c=' + newRec.TotalAmountPromised__c);

            Decimal debtTotal = (relatedDebt != null && relatedDebt.TotalAmount__c != null) ? relatedDebt.TotalAmount__c : 0;
            Decimal promised  = (newRec.TotalAmountPromised__c != null) ? newRec.TotalAmountPromised__c : 0;

            if (debtTotal != 0 && !newRec.PartialPayment_BOL__c) {
                newRec.WriteOffAmount_CUR__c = (debtTotal - promised).setScale(2);
            }

        }
    }

    /**
     * @description Método que, cuando se crea una nueva Promise con el campo "Last Promise" a TRUE O una Promise cambia su estado a "Broken", 
     *              desactiva las Promise Installment asociadas a esa Promise
     * @param List<Promise__c> newRecordList
     * @return void
     */
    public static void updatePromiseInstallments_Inactive(List<Promise__c> promiseList) {
        List<PromisesInstallment__c> installmentsToUpdate =  new List<PromisesInstallment__c>();

        Set<Id> promiseIds = new Set<Id>();
        for (Promise__c p : promiseList) {
            promiseIds.add(p.Id);
        }

        List<PromisesInstallment__c> pInstallmentList = new List<PromisesInstallment__c>(
            [SELECT Id, IsActive_BOL__c
            FROM PromisesInstallment__c
            WHERE Promise_REL__c IN: promiseIds 
            AND IsActive_BOL__c = true]);

        for(PromisesInstallment__c inst : pInstallmentList){
            inst.IsActive_BOL__c = false;
            installmentsToUpdate.add(inst);
        }

        if (!installmentsToUpdate.isEmpty()) {
            try {
                update installmentsToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar el campo "Active" en las Promise Installments: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Método que, cuando se crea una nueva Promise actualiza el campo "Installment Amount" de la Promise si está vacío
     *              o el Nº de Installments si está vacío
     * @param List<Promise__c> newRecordList
     * @return void
     */
    public static void updatePromise_InstallmentAmount(List<Promise__c> newRecordList) {
        
        for (Promise__c newRec : newRecordList) {

            if ((newRec.InstallmentsAmount__c == null || newRec.InstallmentsAmount__c == 0) 
                && (newRec.TotalAmountPromised__c != null && newRec.TotalAmountPromised__c != 0)
                && (newRec.NumberOfInstallments__c != null && newRec.NumberOfInstallments__c != 0) ) {
                
                    newRec.InstallmentsAmount__c = newRec.TotalAmountPromised__c / newRec.NumberOfInstallments__c;
               
            }
            if ((newRec.NumberOfInstallments__c == null || newRec.NumberOfInstallments__c == 0) 
                && (newRec.InstallmentsAmount__c != null && newRec.InstallmentsAmount__c != 0) 
                && (newRec.TotalAmountPromised__c != null && newRec.TotalAmountPromised__c != 0)){
                
                Decimal num;   
                num = newRec.TotalAmountPromised__c / newRec.InstallmentsAmount__c;
                newRec.NumberOfInstallments__c = num.intValue() + 1;
            }
        }
    }

    /**
     * @description Método que, cuando se crea modifica el campo "Total Amount Promised" o "Number Of Installments" de una Promise, 
     *              borra todos los Installments asociados y llama al método createPromisesInstallment para crear de nuevo
     * @param List<Promise__c> newRecordList
     * @return void
     */
    public static void updatePromiseInstallments(List<Promise__c> newRecordList, Map<Id, Promise__c> oldRecordMap) {
        Set<Id> promiseIds = new Set<Id>();
        List<Promise__c> promiseToUpdate =  new List<Promise__c>();
       
        for (Promise__c newRec : newRecordList) {
            Promise__c oldRec = oldRecordMap.get(newRec.Id);

            if ((newRec.TotalAmountPromised__c != oldRec.TotalAmountPromised__c) || (newRec.NumberOfInstallments__c != oldRec.NumberOfInstallments__c)) {
                
                promiseIds.add(newRec.Id);
            }
        }

        if (!promiseIds.isEmpty()) {

            List<PromisesInstallment__c> installmentsToDelete = new List<PromisesInstallment__c>(
                [SELECT Id
                FROM PromisesInstallment__c
                WHERE Promise_REL__c IN: promiseIds]);

            //Borramos las Installments asociadas a la Promise
            if (!installmentsToDelete.isEmpty()) {
                try {
                    delete installmentsToDelete;
                } catch (DmlException e) {
                    System.debug('Error al borrar las Promise Installments asociadas a la Promise' + e.getMessage());
                }
            }

            List<Promise__c> promiseList = [SELECT Id, Debt_REL__c, TotalAmountPromised__c, InstallmentsAmount__c, PaymentDayOfMonth_SEL__c,
                                                NumberOfInstallments__c, StartDate_DAT__c, Frequency_SEL__c, PaymentPlanSelected_SEL__c
                                        FROM Promise__c 
                                        WHERE Id =: promiseIds];

            for(Promise__c promise: promiseList){
                promise.InstallmentsAmount__c = promise.TotalAmountPromised__c / promise.NumberOfInstallments__c;

                promiseToUpdate.add(promise);
            }

            //Actulizamos el campo InstallmentsAmount__c en la Promise
            if (!promiseToUpdate.isEmpty()) {
                try {
                    update promiseToUpdate;
                } catch (DmlException e) {
                    System.debug('Error al actualizar el "Installment Amount" de la Promise' + e.getMessage());
                }
            }
            //Llamamos al metodo de creación de Promise Installmentes y le pasamos la lista de Promises
            createPromisesInstallment(promiseList);
        }
    }

    /**
     * @description Método que, cuando se crea una nueva Promise actualiza el campo "Promise Creation Date" de la Promise si está vacío
     * @param List<Promise__c> newRecordList
     * @return void
     */
    public static void updatePromise_CreationDate(List<Promise__c> newRecordList) {
        
        for (Promise__c newRec : newRecordList) {

            if (newRec.PromiseCreationdate__c == null) {
                
                newRec.PromiseCreationdate__c = System.Today();
               
            }
        }
    }

    /**
     * @description Método que, cuando se crea una nueva Promise o se actualiza una existente, mira que no se sobrepasen los valores
     *              marcados en el Pricing de la Deuda como Máx Nº Installment y Min Amount Installment
     * @param List<Promise__c> newRecordList
     * @return void
     */
    public static void errorMessage_ExceedPricingValues(List<Promise__c> newRecordList) {
        Set<Id> debtIdsToCheck = new Set<Id>();
        Set<Id> pricingToCheck = new Set<Id>();
        Map<Id,Pricing__c> pricingByDebtId = new Map<Id,Pricing__c>();
    
        for (Promise__c newPromise : newRecordList) {
            if (newPromise.Debt_REL__c != null) {
                debtIdsToCheck.add(newPromise.Debt_REL__c);
                pricingToCheck.add(newPromise.Debt_REL__r.Pricing_REL__c);
            }
        }
        if (debtIdsToCheck.isEmpty()) return;
        
        List<Debt__c> debtList = [SELECT Id, Pricing_REL__c FROM Debt__c WHERE Id IN :debtIdsToCheck];
        for(Debt__c db: debtList){
            pricingToCheck.add(db.Pricing_REL__c);
        }
        
        if (pricingToCheck.isEmpty()) return;

        for (Pricing__c p : [SELECT Id, MaximumInstallments_NUM__c, MinAmountInstallment_NUM__c, Debt_REL__c
                            FROM Pricing__c
                            WHERE Id IN :pricingToCheck
        ]) {
            if (p.Debt_REL__c != null) {
                pricingByDebtId.put(p.Debt_REL__c, p);
            }
        }
        
        for(Promise__c promise: newRecordList){
            if(promise.Debt_REL__c != null && pricingByDebtId.containsKey(promise.Debt_REL__c)){
                if(promise.NumberOfInstallments__c != null && 
                    promise.NumberOfInstallments__c > pricingByDebtId.get(promise.Debt_REL__c).MaximumInstallments_NUM__c){
                    promise.NumberOfInstallments__c.addError(Label.Error_Promise_MaxNumInstallment);
                }
                if(promise.InstallmentsAmount__c != null &&
                    promise.InstallmentsAmount__c < pricingByDebtId.get(promise.Debt_REL__c).MinAmountInstallment_NUM__c){
                    promise.InstallmentsAmount__c.addError(Label.Error_Promise_MinAmountInstallment);
                }
            }
        }
    }

}