/**
 * @description       : ContactDataHelper Class
 * @author            : Horizon CX
 * @last modified on  : 21/08/2025
 * @last modified by  : Horizon CX
 *      - 14/10/2025  : Se añade un método para validar que solo haya un CD marcado como OK for communication, de email y Phone, a true para cada Debt y Customer
 *      - 15/10/2025  : Se modifican los métodos updatePersonAccountContact_insert y updatePersonAccountContact_update para que se contemple el campo IsActive si el campo OK for communication a false
**/
public with sharing class ContactDataHelper {
    
    /**
     * @description Método que, en la creación de ContactData, evalua y actualiza los campo "Phone" y "PersonEmail" del PersonAccount vinculado con los CD marcados como "OK for communication"
     * @param List<ContactData__c> newRecordList
     * @return void
     */
    public static void updatePersonAccountContact_insert(List<ContactData__c> newRecordList) {
        if (newRecordList == null || newRecordList.isEmpty()) return;
        
        List<Account> debtorToUpdate =  new List<Account>();

        Set<Id> accountIds = new Set<Id>();
        Set<Id> debtIds = new Set<Id>();

        // Recolectar IDs de Accounts y Debts de los ContactData entrantes
        for (ContactData__c cData : newRecordList) {
            if (cData.Customer_REL__c != null) accountIds.add(cData.Customer_REL__c);
            if (cData.Debt_REL__c != null) debtIds.add(cData.Debt_REL__c);
        }

        if (accountIds.isEmpty() && debtIds.isEmpty()) return;

        // Obtener Accounts relacionados a las Debts
        Set<Id> allAccountIds = new Set<Id>();
        allAccountIds.addAll(accountIds);

        Map<Id, Set<Id>> debtToAccounts = new Map<Id, Set<Id>>();
        if (!debtIds.isEmpty()) {
            for (DebtCustomer__c dc : [
                SELECT Debt_REL__c, Customer_REL__c
                FROM DebtCustomer__c
                WHERE Debt_REL__c IN :debtIds
                AND RelationshipType__c = 'Primary'
            ]) {
                allAccountIds.add(dc.Customer_REL__c);
                if (!debtToAccounts.containsKey(dc.Debt_REL__c)) debtToAccounts.put(dc.Debt_REL__c, new Set<Id>());
                debtToAccounts.get(dc.Debt_REL__c).add(dc.Customer_REL__c);
            }
        }

        if (allAccountIds.isEmpty()) return;

        // Consultar todos los ContactData de esos PersonAccounts y Debts ( los marcados como OK for communication y los marcados como IsValid__c y IsContactable__c)
        List<ContactData__c> allContactData = [
            SELECT Id, Customer_REL__c, Debt_REL__c, ContactDataType_SEL__c, ContactDataValue__c, OK_Communications_BOL__c, 
            IsContactable__c, IsValid__c, InvalidsinceTimestamp__c, PriorityScore_NUM__c, CreatedDate, LastValidationdate__c
            FROM ContactData__c
            WHERE /*OK_Communications_BOL__c = true
            AND*/ (Customer_REL__c IN :allAccountIds 
                OR Debt_REL__c IN :debtIds)
        ];

        if (allContactData.isEmpty()) return;

        // Mapear ContactData por Account
        Map<Id, List<ContactData__c>> contactDataByAccountId = new Map<Id, List<ContactData__c>>();
        for (ContactData__c cd : allContactData) {
            Set<Id> accountsForCD = new Set<Id>();
            if (cd.Customer_REL__c != null) accountsForCD.add(cd.Customer_REL__c);
            if (cd.Debt_REL__c != null && debtToAccounts.containsKey(cd.Debt_REL__c)) {
                accountsForCD.addAll(debtToAccounts.get(cd.Debt_REL__c));
            }

            for (Id accId : accountsForCD) {
                if (!contactDataByAccountId.containsKey(accId)) {
                    contactDataByAccountId.put(accId, new List<ContactData__c>());
                }
                contactDataByAccountId.get(accId).add(cd);
            }
        }

        // Obtener Accounts a actualizar
        List<Account> accountsToUpdate = [
            SELECT Id, Phone, PersonEmail
            FROM Account
            WHERE Id IN :allAccountIds
        ];

        for (Account acc : accountsToUpdate) {
            List<ContactData__c> relatedCDs = contactDataByAccountId.get(acc.Id);
            if (relatedCDs == null || relatedCDs.isEmpty()) continue;

            // --- INICIO: MODIFICACIÓN 15/10/2025 --- //
            ContactData__c selectedEmail;
            ContactData__c selectedPhone;
            // --- 1a PASADA: buscar OK for communication ---
            for (ContactData__c cd : relatedCDs) {
                if (cd.ContactDataValue__c == null) continue;

                if (cd.ContactDataType_SEL__c == 'Email' && cd.OK_Communications_BOL__c) {
                    selectedEmail = cd;
                    acc.PersonEmail = cd.ContactDataValue__c;
                    acc.UseEmailCommunication_BOL__c = true;
                }
                if ((cd.ContactDataType_SEL__c == 'Phone' || cd.ContactDataType_SEL__c == 'MobilePhone') && cd.OK_Communications_BOL__c) {
                    selectedPhone = cd;
                    acc.Phone = cd.ContactDataValue__c;
                    acc.UsePhoneCommunications_BOL__c = true;
                }
            }
            // --- 2a PASADA: si no hay OK, buscar IsValid con mayor PriorityScore ---
            if (selectedEmail == null) {
                ContactData__c bestEmail = getBestCandidate(relatedCDs, new Set<String>{'Email'});
                if (bestEmail != null && bestEmail.ContactDataValue__c != null) {
                    if (acc.PersonEmail == null || acc.PersonEmail != bestEmail.ContactDataValue__c) {
                        acc.PersonEmail = bestEmail.ContactDataValue__c;
                        acc.UseEmailCommunication_BOL__c = false;
                        
                    }
                }
            }
            if (selectedPhone == null) {
                ContactData__c bestPhone = getBestCandidate(relatedCDs, new Set<String>{'Phone','MobilePhone'});
                if (bestPhone != null && bestPhone.ContactDataValue__c != null) {
                    if (acc.Phone == null || acc.Phone != bestPhone.ContactDataValue__c) {
                        acc.Phone = bestPhone.ContactDataValue__c;
                        acc.UsePhoneCommunications_BOL__c = false;
                    }
                }
            }
            // -- FIN : MODIFICACIÓN 15/10/2025 -- //


            // -- Comentado día 15/10/2025 -- //
            // Tomar el primer Email y Phone/MobilePhone encontrado
            /*for (ContactData__c cd : relatedCDs) {
                if (cd.ContactDataType_SEL__c == 'Email' && cd.ContactDataValue__c != null) {
                    acc.PersonEmail = cd.ContactDataValue__c;
                }
                if ((cd.ContactDataType_SEL__c == 'Phone' || cd.ContactDataType_SEL__c == 'MobilePhone') &&
                    cd.ContactDataValue__c != null) {
                    acc.Phone = cd.ContactDataValue__c;
                }
            }*/

            debtorToUpdate.add(acc);
        }
        if (!debtorToUpdate.isEmpty()) {
            try {
                update debtorToUpdate;
            } catch (DmlException e) {
                System.debug('Error al actualizar PersonAccounts: ' + e.getMessage());
            }
        }

    }

    /**
     * @description Método que, cuando se actualiza el campo IsValid__c o PriorityScore_NUM__c en un registro de ContactData, evalua y actualiza los campo "Phone" y "PersonEmail" del PersonAccount vinculado
     * @param List<ContactData__c> newRecordList
     * @return void
     */
    public static void updatePersonAccountContact_update(List<ContactData__c> newList, Map<Id, ContactData__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;
    
        /*Set<Id> personAccountIds = new Set<Id>();
        Map<Id, List<ContactData__c>> contactDataByPA = new Map<Id, List<ContactData__c>>();
        List<Account> personAccToUpdates = new List<Account>();*/

        List<ContactData__c> contactDataToProcess = new List<ContactData__c>();
        // Identificar PersonAccounts afectados
        for (ContactData__c newC : newList) {
            ContactData__c oldC = oldMap.get(newC.Id);
    
            // Solo nos interesan si cambia el valor "Ok for communications"
            if (oldC.OK_Communications_BOL__c != newC.OK_Communications_BOL__c ||
                oldC.IsValid__c != newC.IsValid__c || 
                oldC.PriorityScore_NUM__c != newC.PriorityScore_NUM__c) {
                    contactDataToProcess.add(newC);
            }
        }

        if(!contactDataToProcess.isEmpty()){
            updatePersonAccountContact_insert(contactDataToProcess);
        }
    }

    /**
     * @description Método que devuelve el mejor candidato entre una lista, filtrado por tipos y con mayor PriorityScore
     * @param List<ContactData__c> candidates
     * @param Set<String> types
     * @return ContactData__c
     */
    public static ContactData__c getBestCandidate(List<ContactData__c> candidates, Set<String> types) {
        ContactData__c best = null;
        for (ContactData__c c : candidates) {
            if (types.contains(c.ContactDataType_SEL__c)) {
                if (best == null 
                    || c.PriorityScore_NUM__c > best.PriorityScore_NUM__c 
                    || (c.PriorityScore_NUM__c == best.PriorityScore_NUM__c && c.LastValidationdate__c > best.LastValidationdate__c)) {
                    best = c;
                }
            }
        }
        return best;
    }

    /**
     * @description Método que, cuando se crea o actualiza un ContactData con el campo "OK for communication" a TRUE, actualiza el campo "OK for communication" a False del resto de CD asociados a la DEBT y CUSTOMER
     * @param List<ContactData__c> newRecordList
     * @return void
     */
    public static void updateActiveOKforCommCD(List<ContactData__c> newRecordList) {
        if (newRecordList == null || newRecordList.isEmpty()) return;
    
        Set<Id> debtIds = new Set<Id>();
        Set<Id> customerIds = new Set<Id>();
        List<ContactData__c> activeContactData = new List<ContactData__c>();
    
        // Filtrar solo los registros relevantes
        for (ContactData__c cd : newRecordList) {
            if (cd.OK_Communications_BOL__c &&
                (cd.ContactDataType_SEL__c == 'Email' ||
                 cd.ContactDataType_SEL__c == 'Phone' ||
                 cd.ContactDataType_SEL__c == 'MobilePhone') &&
                (cd.Debt_REL__c != null || cd.Customer_REL__c != null)) {
    
                activeContactData.add(cd);
                if (cd.Debt_REL__c != null) debtIds.add(cd.Debt_REL__c);
                if (cd.Customer_REL__c != null) customerIds.add(cd.Customer_REL__c);
            }
        }
    
        if (activeContactData.isEmpty()) return;
    
        // Obtener todos los ContactData relacionados tanto con Debt como con Customer
        List<ContactData__c> relatedCDs = [
            SELECT Id, Debt_REL__c, Customer_REL__c, ContactDataType_SEL__c, OK_Communications_BOL__c
            FROM ContactData__c
            WHERE OK_Communications_BOL__c = TRUE
            AND (ContactDataType_SEL__c IN ('Email', 'Phone', 'MobilePhone'))
            AND (
                (Debt_REL__c IN :debtIds AND Debt_REL__c != NULL) OR
                (Customer_REL__c IN :customerIds AND Customer_REL__c != NULL)
            )
        ];
    
        if (relatedCDs.isEmpty()) return;
    
        // Crear mapas para agrupar por tipo de relación
        Map<Id, List<ContactData__c>> cdsByDebt = new Map<Id, List<ContactData__c>>();
        Map<Id, List<ContactData__c>> cdsByCustomer = new Map<Id, List<ContactData__c>>();
    
        for (ContactData__c rel : relatedCDs) {
            if (rel.Debt_REL__c != null) {
                if (!cdsByDebt.containsKey(rel.Debt_REL__c)) {
                    cdsByDebt.put(rel.Debt_REL__c, new List<ContactData__c>());
                }
                cdsByDebt.get(rel.Debt_REL__c).add(rel);
            }
    
            if (rel.Customer_REL__c != null) {
                if (!cdsByCustomer.containsKey(rel.Customer_REL__c)) {
                    cdsByCustomer.put(rel.Customer_REL__c, new List<ContactData__c>());
                }
                cdsByCustomer.get(rel.Customer_REL__c).add(rel);
            }
        }
    
        // Marcar los duplicados a desactivar
        Map<Id, ContactData__c> toUpdateMap = new Map<Id, ContactData__c>();
    
        for (ContactData__c cd : activeContactData) {
            Boolean isEmail = cd.ContactDataType_SEL__c == 'Email';
            Boolean isPhoneType = (cd.ContactDataType_SEL__c == 'Phone' || cd.ContactDataType_SEL__c == 'MobilePhone');
    
            List<ContactData__c> relatedList = new List<ContactData__c>();
    
            if (cd.Debt_REL__c != null && cdsByDebt.containsKey(cd.Debt_REL__c))
                relatedList.addAll(cdsByDebt.get(cd.Debt_REL__c));
            if (cd.Customer_REL__c != null && cdsByCustomer.containsKey(cd.Customer_REL__c))
                relatedList.addAll(cdsByCustomer.get(cd.Customer_REL__c));
    
            for (ContactData__c rel : relatedList) {
                if (rel.Id == cd.Id) continue;
    
                Boolean sameType = (isEmail && rel.ContactDataType_SEL__c == 'Email') ||
                                   (isPhoneType && (rel.ContactDataType_SEL__c == 'Phone' || rel.ContactDataType_SEL__c == 'MobilePhone'));
    
                if (sameType) {
                    rel.OK_Communications_BOL__c = false;
                    toUpdateMap.put(rel.Id, rel);
                }
            }
        }
        System.debug('toUpdateMap --> '+toUpdateMap);
        // Actualizar los ContactData marcados
        if (!toUpdateMap.isEmpty()) {
            try {
                update toUpdateMap.values();
            } catch (DmlException e) {
                System.debug('Error al actualizar ContactData: ' + e.getMessage());
            }
        }
    }
    
}