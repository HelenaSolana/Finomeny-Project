/**
 * @description       : PaymentHelper Class
 * @author            : Horizon CX
 * @last modified on  : 12/08/2025
 * @last modified by  : Horizon CX
**/
public with sharing class PaymentHelper {
    /**
     * @description Método que actualiza el campo "Paid Amount" de la Promise y Promise Installment cuando un Payment se crea y el campo "Transaction direction" es Received
     * @param List<Payment__c> newRecordList
     * @return void
     */
    public static void updatePromise_PaidAmount(List<Payment__c> newRecordList) {
        List<Promise__c> promiseToUpdate =  new List<Promise__c>();
        List<PromisesInstallment__c> promiseInstallmentToUpdate =  new List<PromisesInstallment__c>();
        Set<Id> promisetId = new Set<Id>();
        Set<Id> promiseInstallmenttId = new Set<Id>();

        for (Payment__c payment : newRecordList) {
            if (payment.Promise_REL__c != null || payment.PromisesInstallment_REL__c != null) {
                promisetId.add(payment.Promise_REL__c);
                promiseInstallmenttId.add(payment.PromisesInstallment_REL__c);
            }
        }

        Map<Id,Promise__c> promiseMap = new Map<Id,Promise__c>(
                [SELECT Id, PaidAmount__c  
                FROM Promise__c 
                WHERE Id 
                IN :promisetId]);
        Map<Id,PromisesInstallment__c> promiseInstallmentMap = new Map<Id,PromisesInstallment__c>(
                [SELECT Id, PaidAmount__c  
                FROM PromisesInstallment__c 
                WHERE Id 
                IN :promiseInstallmenttId]);

        for (Payment__c newRec : newRecordList) {
            if (newRec.TransactionAmount__c != null && newRec.Transactiondirection_SEL__c == 'Received') {
                if(promiseMap.containsKey(newRec.Promise_REL__c)){
                    Promise__c relatedPromise = promiseMap.get(newRec.Promise_REL__c);
                    
                    relatedPromise.PaidAmount__c = (relatedPromise.PaidAmount__c != null ? relatedPromise.PaidAmount__c : 0) + newRec.TransactionAmount__c;
                    promiseToUpdate.add(relatedPromise);
                }
                if(promiseInstallmentMap.containsKey(newRec.PromisesInstallment_REL__c)){
                    PromisesInstallment__c relatedPInstallment = promiseInstallmentMap.get(newRec.PromisesInstallment_REL__c);
                    
                    relatedPInstallment.PaidAmount__c = (relatedPInstallment.PaidAmount__c != null ? relatedPInstallment.PaidAmount__c : 0) + newRec.TransactionAmount__c;
                    promiseInstallmentToUpdate.add(relatedPInstallment);
                }
            } else if(newRec.TransactionAmount__c != null && newRec.Transactiondirection_SEL__c == 'Returned'){
                if(promiseMap.containsKey(newRec.Promise_REL__c)){
                    Promise__c relatedPromise = promiseMap.get(newRec.Promise_REL__c);
                    
                    relatedPromise.PaidAmount__c = (relatedPromise.PaidAmount__c != null ? relatedPromise.PaidAmount__c : 0) - newRec.TransactionAmount__c;
                    promiseToUpdate.add(relatedPromise);
                }
                if(promiseInstallmentMap.containsKey(newRec.PromisesInstallment_REL__c)){
                    PromisesInstallment__c relatedPInstallment = promiseInstallmentMap.get(newRec.PromisesInstallment_REL__c);
                
                    relatedPInstallment.PaidAmount__c = (relatedPInstallment.PaidAmount__c != null ? relatedPInstallment.PaidAmount__c : 0) - newRec.TransactionAmount__c;
                    promiseInstallmentToUpdate.add(relatedPInstallment);
                }
            }
        }
        if (!promiseToUpdate.isEmpty()) {
            try {
                update promiseToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar el campo "Paid Amount" en Promise' + e.getMessage());
            }
        }
        if (!promiseInstallmentToUpdate.isEmpty()) {
            try {
                update promiseInstallmentToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar el campo "Paid Amount" en Promise Installment' + e.getMessage());
            }
        }
    }
}