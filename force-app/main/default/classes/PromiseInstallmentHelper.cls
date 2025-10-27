/**
 * @description       : PromiseInstallmentHelper Class
 * @author            : Horizon CX
 * @last modified on  : 12/08/2025
 * @last modified by  : Horizon CX
**/
public with sharing class PromiseInstallmentHelper {
    /**
     * @description Método que actualiza los campos "Broken Installment Nº" y "Status Potencial" de Promise cuando una Promise Installment cambia su estado a "Broken"
     * @param List<PromisesInstallment__c> newRecordList
     * @param Map<Id,PromisesInstallment__c> oldRecordMap
     * @return void
     */
    /*public static void updatePromise_BrokenInstallment(List<PromisesInstallment__c> newRecordList, Map<Id, PromisesInstallment__c> oldRecordMap) {
        List<Promise__c> promiseToUpdate =  new List<Promise__c>();
        
        Set<Id> promisetId = new Set<Id>();
        for (PromisesInstallment__c promiseInst : newRecordList) {
            if (promiseInst.Promise_REL__c != null) {
                promisetId.add(promiseInst.Promise_REL__c);
            }
        }
        Map<Id,Promise__c> promiseMap = new Map<Id, Promise__c>(
                [SELECT Id, BrokenInstallement_NUM__c, StatusPotential_SEL__c  
                FROM Promise__c 
                WHERE Id 
                IN :promisetId]);

        for (PromisesInstallment__c newRec : newRecordList) {
            PromisesInstallment__c oldRec = oldRecordMap.get(newRec.Id);

            if (newRec.Status_FOR__c == 'Broken' && newRec.Status_FOR__c != oldRec.Status_FOR__c && promiseMap.containsKey(newRec.Promise_REL__c)) {
                Promise__c relatedPromise = promiseMap.get(newRec.Promise_REL__c);
                if(relatedPromise.StatusPotential_SEL__c != 'Broken'){
                    relatedPromise.BrokenInstallement_NUM__c = newRec.NInstallments__c;
                    relatedPromise.StatusPotential_SEL__c = 'Broken';
                    promiseToUpdate.add(relatedPromise);
                }
            }
        }
        if (!promiseToUpdate.isEmpty()) {
            try {
                update promiseToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar el campo "Broken Installment Nº" en Promise' + e.getMessage());
            }
        }
    }*/

    /**
     * @description Método que actualiza el campo "Status Potencial" de Promise cuando una Promise Installment cambia su estado
     * @param List<PromisesInstallment__c> newRecordList
     * @param Map<Id,PromisesInstallment__c> oldRecordMap
     * @return void
     */
    public static void updatePromise_Status(List<PromisesInstallment__c> newRecordList, Map<Id, PromisesInstallment__c> oldRecordMap) {
        List<Promise__c> promiseToUpdate =  new List<Promise__c>();
        
        Set<Id> promisetId = new Set<Id>();
        for (PromisesInstallment__c promiseInst : newRecordList) {
            if (promiseInst.Promise_REL__c != null) {
                promisetId.add(promiseInst.Promise_REL__c);
            }
        }

        Map<Id,Promise__c> promiseMap = new Map<Id, Promise__c>(
                [SELECT Id, StatusPotential_SEL__c, NumberOfInstallments__c, PaidInstallments_ROL__c, BrokenInstallement_NUM__c
                FROM Promise__c 
                WHERE Id 
                IN :promisetId]);

        for (PromisesInstallment__c newRec : newRecordList) {
            PromisesInstallment__c oldRec = oldRecordMap.get(newRec.Id);

            if (newRec.Status_FOR__c != oldRec.Status_FOR__c && newRec.IsActive_BOL__c && promiseMap.containsKey(newRec.Promise_REL__c)) {
                Promise__c relatedPromise = promiseMap.get(newRec.Promise_REL__c);

                if(newRec.Status_FOR__c == 'Pre-Broken' && oldRec.Status_FOR__c == 'Pending'){
                    relatedPromise.StatusPotential_SEL__c = 'Pre-Broken';
                    promiseToUpdate.add(relatedPromise);
                }else if(newRec.Status_FOR__c == 'Paid' && oldRec.Status_FOR__c == 'Pre-Broken' 
                        && relatedPromise.NumberOfInstallments__c != relatedPromise.PaidInstallments_ROL__c){
                    relatedPromise.StatusPotential_SEL__c = 'Pending';
                    promiseToUpdate.add(relatedPromise);
                }else if(newRec.Status_FOR__c == 'Broken' && oldRec.Status_FOR__c == 'Pre-Broken' && relatedPromise.StatusPotential_SEL__c != 'Broken'){
                    relatedPromise.BrokenInstallement_NUM__c = newRec.NInstallments__c;
                    relatedPromise.StatusPotential_SEL__c = 'Broken';
                    promiseToUpdate.add(relatedPromise);
                }else{
                    //No se hace nada
                }
            }
        }
        if (!promiseToUpdate.isEmpty()) {
            try {
                update promiseToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar el campo Status en Promise' + e.getMessage());
            }
        }
    }

    /**
     * @description Método que actualiza el campo "Potencial Next Payment date" de Promise cuando una Promise Installment cambia su estado a "Paid"
     * @param List<PromisesInstallment__c> newRecordList
     * @param Map<Id,PromisesInstallment__c> oldRecordMap
     * @return void
     */
    public static void updatePromise_NextPaymentDay(List<PromisesInstallment__c> newRecordList, Map<Id, PromisesInstallment__c> oldRecordMap) {
        List<Promise__c> promiseToUpdate =  new List<Promise__c>();
        Set<Id> promisetId = new Set<Id>();
        Map<Id, Id> newLastPromiseInstalmentIdsByDebt = new Map<Id, Id>();

        for (PromisesInstallment__c promiseInst : newRecordList) {
            if (promiseInst.Promise_REL__c != null) {
                promisetId.add(promiseInst.Promise_REL__c);
            }
        }

        if (promisetId.isEmpty()) return;
        Map<Id,Promise__c> promiseMap = new Map<Id, Promise__c>(
                [SELECT Id, PotentialNextPaymentdate__c 
                FROM Promise__c 
                WHERE Id IN :promisetId]);

        List<PromisesInstallment__c> promiseInstallmentList = new List<PromisesInstallment__c>(
                [SELECT Id, Status_FOR__c, NInstallments__c, PaymentDate__c
                FROM PromisesInstallment__c 
                WHERE Promise_REL__c IN :promisetId 
                AND Status_FOR__c = 'Pending' AND InstallmentsCompleted_FOR__c = false
                ORDER BY NInstallments__c ASC]);

        for (PromisesInstallment__c newRec : newRecordList) {
            PromisesInstallment__c oldRec = oldRecordMap.get(newRec.Id);

            if(newRec.Status_FOR__c == 'Paid' && newRec.Status_FOR__c != oldRec.Status_FOR__c && !promiseInstallmentList.isEmpty()){
                Promise__c relatedPromise = promiseMap.get(newRec.Promise_REL__c);
                relatedPromise.PotentialNextPaymentdate__c = promiseInstallmentList[0].PaymentDate__c;
                promiseToUpdate.add(relatedPromise);
            }
        }
        if (!promiseToUpdate.isEmpty()) {
            try {
                update promiseToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar el campo "Potencial Next Payment Day" en Promise' + e.getMessage());
            }
        }
    }
}