trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    /* Mecanismos de control triggers, permite apargarlos en caso de que sea necesario a través de una custom setting */
    Id currentUserId = UserInfo.getUserId();
    Automation_Settings__c triggersEnabled = Automation_Settings__c.getInstance(currentUserId);
    if(triggersEnabled.Triggers_Enabled__c  != null && triggersEnabled.Triggers_Enabled__c  == false) return;
    /*-----------------------------------------------------------------------------------------------------------------*/
    TriggerHandler handler = new CaseHandler(Trigger.size);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
           // handler.beforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
        when BEFORE_DELETE {
           // handler.beforeDelete(Trigger.old, Trigger.oldMap);
        }
        when AFTER_INSERT {
            handler.afterInsert(Trigger.new, Trigger.newMap);
        }
        when AFTER_UPDATE {
            //handler.afterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
        when AFTER_DELETE {
           // handler.afterDelete(Trigger.old, Trigger.oldMap);
        }
        when AFTER_UNDELETE {
           // handler.afterUndelete(Trigger.new, Trigger.newMap);
        }
    }
}