/**
* @description Controller class for Work Order component, used mainly for creating recurring Work Orders/Jobs
* @className WorkOrderController
* @author Tushar Kaore
* @lastModified 24/01/2022
*/

public with sharing class WorkOrderController {

    /**
     * Fetching all the details for given Work Order/Job record
     */
    @AuraEnabled    
    public static WorkOrder fetchWordOrder(String workOrderId){    
        return [SELECT AccountId,Address,AssetId,BusinessHoursId,CaseId,City,CompanyRevenue__c,
                ContactId,Country,CreatedById,CreatedDate,CrewSize__c,Description,Discount,Duration,
                DurationInMinutes,DurationType,EndDate,EntitlementId,GeocodeAccuracy,GrandTotal,Id,
                IsClosed,IsDeleted,IsStopped,JobDate__c,LastModifiedById,LastModifiedDate,
                LastReferencedDate,LastViewedDate,Latitude,LineItemCount,LocationId,Longitude,
                MilestoneStatus,OwnerId,ParentWorkOrderId,PostalCode,Pricebook2Id,Priority,
                RootWorkOrderId,ServiceAppointmentCount,ServiceContractId,ServiceTerritoryId,
                SlaExitDate,SlaStartDate,StartDate,State,Status,StatusCategory,StopStartDate,
                Street,Subject,Subtotal,SystemModstamp,Tax,TotalPrice,TotalUnits__c,
                WorkOrderNumber,WorkTypeId FROM WorkOrder wHERE Id =: workOrderId];           
    }

    /**
     * Creating a clone from given Work Order record
     */
    public static WorkOrder copyWordOrder(WorkOrder sourceObj){
        WorkOrder newWorkOrder = new WorkOrder();
        newWorkOrder = sourceObj.clone(false,false);
        return newWorkOrder;
    }

    /**
     * Creating recurring Work Order/Jobs as per the recurrence pattern from user
     */
    @AuraEnabled    
    public static Object createRecurringWorkOrders(String scheduleJsonStr,Id currentWorkOrderId){
        try {
            RecurringSchedule schedule = (RecurringSchedule)JSON.deserialize(scheduleJsonStr,RecurringSchedule.class);
            // Fetching the details for parent Work Order/Job
            WorkOrder currentWorkOrder= fetchWordOrder(currentWorkOrderId);

            String scheduleType = schedule.type;
            Integer noOfOccurences = schedule.noOfOccurences;
            Date stDate = currentWorkOrder.JobDate__c;
            List<WorkOrder> newWorkOrderToInsert = new List<WorkOrder>();
            
            if(scheduleType == 'Weekly' || scheduleType == 'BiWeekly'){
                //Increment days by 7 for weekly and 14 for BiWeekly
                Integer dayMultiplier = scheduleType == 'Weekly' ? 7: 14;
                //Capturing the days selection
                Set<Integer> daysOfWeek = new Set<Integer>();
                if(schedule.sunday != null && schedule.sunday){
                    daysOfWeek.add(0);
                }
                if(schedule.monday != null && schedule.monday){
                    daysOfWeek.add(1);
                }
                if(schedule.tuesday != null && schedule.tuesday){
                    daysOfWeek.add(2);
                }
                if(schedule.wednesday != null &&  schedule.wednesday){
                    daysOfWeek.add(3);
                }
                if(schedule.thursday != null && schedule.thursday){
                    daysOfWeek.add(4);
                }
                if(schedule.friday != null &&  schedule.friday){
                    daysOfWeek.add(5);
                }
                if(schedule.saturday != null &&  schedule.saturday){
                    daysOfWeek.add(6);
                }
                //iteration for each day of the week
                for(Integer i=0;i<7;i++){
                    Integer currDay = dayOfWeekNumber(stDate);
                    if(daysOfWeek.contains(currDay)){
                        Date stTimeTemp = stDate;
                        //iteration for number of ocurrences
                        for(Integer index = 0;index<noOfOccurences;index++){
                            //Cloning the detail as per existing work order/job
                            WorkOrder newWorkOrder = copyWordOrder(currentWorkOrder);
                            newWorkOrder.JobDate__c = stTimeTemp.addDays(dayMultiplier*index);
                            
                            //Skipping the record if date is equal to parent record
                            if(currentWorkOrder.JobDate__c < newWorkOrder.JobDate__c){
                                newWorkOrder.ParentWorkOrderId = currentWorkOrder.Id;
                                newWorkOrder.IsRecurringJob__c = true;
                                newWorkOrderToInsert.add(newWorkOrder);
                            }
                        }        
                    }
                    stDate = stDate.addDays(1);
                }
            }else if(scheduleType == 'Monthly'){
                for(Integer index = 0;index<=noOfOccurences;index++){
                    //Cloning the detail as per existing work order/job
                    WorkOrder newWorkOrder = copyWordOrder(currentWorkOrder);
                    newWorkOrder.JobDate__c = stDate.addMonths(index);

                    //Skipping the record if date is equal to parent record
                    if(currentWorkOrder.JobDate__c < newWorkOrder.JobDate__c){
                        newWorkOrder.ParentWorkOrderId = currentWorkOrder.Id;
                        newWorkOrder.IsRecurringJob__c = true;
                        newWorkOrderToInsert.add(newWorkOrder);
                    }
                }
            }

            if(newWorkOrderToInsert.size() > 0){
                //Marking Work Order/Job as recurring
                currentWorkOrder.IsRecurringJob__c = true;
                newWorkOrderToInsert.add(currentWorkOrder);

                updateExistingLineItemDiscount(currentWorkOrderId);
                upsert newWorkOrderToInsert;
            }
            
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * Adding the discount to the existing line items in case of recurring Work Order/ Job
     */
    private static void updateExistingLineItemDiscount(String workOrderId){
        List<WorkOrderLineItem> lineItems = [SELECT Id FROM  WorkOrderLineItem WHERE WorkOrderId=: workOrderId];
        if(lineItems != null && lineItems.size() > 0){
            for(WorkOrderLineItem lineItem : lineItems){
                lineItem.Discount = 10;
            }
            update lineItems;
        }
    }

    /**
     * Getting the week day of a given date
     */
    public static Integer dayOfWeekNumber(Date dateVar) {
        return Math.mod(Date.newInstance(1900, 1, 7).daysBetween(dateVar),7);
    }

    /**
     * Wrapper class to hold user provided recurrent data
     */

    public class RecurringSchedule{
        public String type;
        public boolean sunday;
        public boolean monday;
        public boolean tuesday;
        public boolean wednesday;
        public boolean thursday;
        public boolean friday;
        public boolean saturday;
        public Integer noOfOccurences;
    }
}