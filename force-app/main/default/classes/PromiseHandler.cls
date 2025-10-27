/**
 * @description       : PromiseHandler Class
 * @author            : Horizon CX
 * @last modified on  : 30/07/2025
 * @last modified by  : Horizon CX
**/
public with sharing class PromiseHandler implements TriggerHandler {
   
	private Integer size; // Number of records being processed in the trigger.

    public PromiseHandler(Integer size) {
        this.size = size;
    }

    public void beforeInsert(List<SObject> newRecords) {
        PromiseHelper.errorMessage_ExceedPricingValues((List<Promise__c>)newRecords);
        PromiseHelper.updatePromise_InstallmentAmount((List<Promise__c>)newRecords);
        PromiseHelper.updatePromise_WriteOffAmount((List<Promise__c>)newRecords);
        PromiseHelper.updatePromise_CreationDate((List<Promise__c>)newRecords);

    	System.debug('Before Insert: Trigger Size: ' + size + ' Trigger CPU Time: ' + Limits.getCpuTime() + ' Trigger Queries: ' + Limits.getQueries());
    }

    public void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        PromiseHelper.errorMessage_ExceedPricingValues((List<Promise__c>)newRecords);
        
        System.debug('Before Update: Trigger Size: ' + size + ' Trigger CPU Time: ' + Limits.getCpuTime() + ' Trigger Queries: ' + Limits.getQueries());
    }

    public void beforeDelete(List<SObject> oldRecords, Map<Id, SObject> oldRecordMap) {
        //Llamar a los métodos del Helper. Evitar meter lógica en el handler (bucles for, ifs...) derivar toda esa lógica a los métodos del helper.    
        
        System.debug('Before Delete: Trigger Size: ' + size + ' Trigger CPU Time: ' + Limits.getCpuTime() + ' Trigger Queries: ' + Limits.getQueries());
    }

    public void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {

        PromiseHelper.createPromisesInstallment((List<Promise__c>)newRecords);
        PromiseHelper.updateDebt_WriteOffAmount((List<Promise__c>)newRecords);
        PromiseHelper.updateLastPromisesCheck((List<Promise__c>)newRecords);

        System.debug('After Insert: Trigger Size: ' + size + ' Trigger CPU Time: ' + Limits.getCpuTime() + ' Trigger Queries: ' + Limits.getQueries());
    }

    public void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        
        PromiseHelper.updateBrokenDate((List<Promise__c>)newRecords, (Map<Id, Promise__c>)oldRecordMap);
        PromiseHelper.updateStatusPromise((List<Promise__c>)newRecords, (Map<Id, Promise__c>)oldRecordMap);
        PromiseHelper.updatePromiseInstallments((List<Promise__c>)newRecords, (Map<Id, Promise__c>)oldRecordMap);
        
        System.debug('After Update: Trigger Size: ' + size + ' Trigger CPU Time: ' + Limits.getCpuTime() + ' Trigger Queries: ' + Limits.getQueries());
    }

    public void afterDelete(List<SObject> oldRecords, Map<Id, SObject> oldRecordMap) {
        //Llamar a los métodos del Helper. Evitar meter lógica en el handler (bucles for, ifs...) derivar toda esa lógica a los métodos del helper.    
        
        System.debug('After Delete: Trigger Size: ' + size + ' Trigger CPU Time: ' + Limits.getCpuTime() + ' Trigger Queries: ' + Limits.getQueries());
    }

    public void afterUndelete(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
        //Llamar a los métodos del Helper. Evitar meter lógica en el handler (bucles for, ifs...) derivar toda esa lógica a los métodos del helper.    
        
        System.debug('After Undelete: Trigger Size: ' + size + ' Trigger CPU Time: ' + Limits.getCpuTime() + ' Trigger Queries: ' + Limits.getQueries());
    }
}