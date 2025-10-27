/**
 * @description       : PromiseInstallmentHandler Class
 * @author            : Horizon CX
 * @last modified on  : 12/08/2025
 * @last modified by  : Horizon CX
**/
public with sharing class PromiseInstallmentHandler implements TriggerHandler {
   
	private Integer size; // Number of records being processed in the trigger.

    public PromiseInstallmentHandler(Integer size) {
        this.size = size;
    }

    public void beforeInsert(List<SObject> newRecords) {
        //Llamar a los métodos del Helper. Evitar meter lógica en el handler (bucles for, ifs...) derivar toda esa lógica a los métodos del helper.    
        
    	System.debug('Before Insert: Trigger Size: ' + size + ' Trigger CPU Time: ' + Limits.getCpuTime() + ' Trigger Queries: ' + Limits.getQueries());
    }

    public void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        //Llamar a los métodos del Helper. Evitar meter lógica en el handler (bucles for, ifs...) derivar toda esa lógica a los métodos del helper.    
        
        System.debug('Before Update: Trigger Size: ' + size + ' Trigger CPU Time: ' + Limits.getCpuTime() + ' Trigger Queries: ' + Limits.getQueries());
    }

    public void beforeDelete(List<SObject> oldRecords, Map<Id, SObject> oldRecordMap) {
        //Llamar a los métodos del Helper. Evitar meter lógica en el handler (bucles for, ifs...) derivar toda esa lógica a los métodos del helper.    
        
        System.debug('Before Delete: Trigger Size: ' + size + ' Trigger CPU Time: ' + Limits.getCpuTime() + ' Trigger Queries: ' + Limits.getQueries());
    }

    public void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
        
        System.debug('After Insert: Trigger Size: ' + size + ' Trigger CPU Time: ' + Limits.getCpuTime() + ' Trigger Queries: ' + Limits.getQueries());
    }

    public void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        PromiseInstallmentHelper.updatePromise_Status((List<PromisesInstallment__c>)newRecords, (Map<Id, PromisesInstallment__c>)oldRecordMap);
        PromiseInstallmentHelper.updatePromise_NextPaymentDay((List<PromisesInstallment__c>)newRecords, (Map<Id, PromisesInstallment__c>)oldRecordMap);
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