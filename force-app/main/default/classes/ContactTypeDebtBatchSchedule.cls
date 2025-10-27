/**
 * @description       : ContactTypeDebtBatchSchedule Class
 * @author            : Horizon CX
 * @last modified on  : 01/08/2025
 * @last modified by  : Horizon CX
**/
global class ContactTypeDebtBatchSchedule implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        ContactTypeDebtBatch batch = new ContactTypeDebtBatch();
        Database.executeBatch(batch, 200);
    }

    // Método para programación estándar
    public static void scheduleDailyAt6AM() {
        scheduleDailyAt6AM(null);
    }

    // Método sobrecargado para permitir nombre personalizado (útil en tests)
    public static void scheduleDailyAt6AM(String jobNameOverride) {
        String cronExp = '0 0 6 * * ?'; // A las 6:00 a. m. todos los días
        String jobName = (jobNameOverride != null) ? jobNameOverride : 'ContactTypeDebtBatchSchedule';
        System.schedule(jobName, cronExp, new ContactTypeDebtBatchSchedule());
    }
}